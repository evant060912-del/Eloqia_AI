from __future__ import annotations

import asyncio
import json
import logging
from typing import Any

from livekit import agents
from livekit.agents import Agent, AgentSession, room_io
from livekit.plugins import liveavatar, openai
from pydantic import ValidationError

from app.config import Settings
from app.mia_context import build_mia_greeting, build_mia_instructions
from app.schemas import LearningContext

logger = logging.getLogger("eloqia.mia_agent")
settings = Settings.from_env()
server = agents.AgentServer()


def _read_job_metadata(raw_metadata: str) -> tuple[str, LearningContext]:
    try:
        payload: Any = json.loads(raw_metadata)
        if not isinstance(payload, dict) or payload.get("schema_version") != 1:
            raise ValueError("Unsupported job metadata schema")

        session_id = payload.get("session_id")
        raw_context = payload.get("context")
        if not isinstance(session_id, str) or len(session_id) > 64:
            raise ValueError("Invalid session identifier")
        if not isinstance(raw_context, dict):
            raise ValueError("Invalid learning context")

        return session_id, LearningContext.model_validate(raw_context)
    except (json.JSONDecodeError, ValueError, ValidationError) as error:
        raise ValueError("Invalid Mia session metadata") from error


@server.rtc_session(agent_name=settings.mia_agent_name)
async def mia_agent(ctx: agents.JobContext) -> None:
    missing = settings.missing_agent_settings()
    if missing:
        logger.error("Mia agent configuration missing: %s", ", ".join(missing))
        return

    try:
        session_id, context = _read_job_metadata(ctx.job.metadata)
    except ValueError:
        logger.warning("Rejected malformed Mia job metadata")
        return

    ctx.log_context_fields = {
        "room_name": ctx.room.name,
        "session_id": session_id,
        "agent_name": settings.mia_agent_name,
    }

    # Wait for the participant before starting the agent
    participant = await ctx.wait_for_participant()

    voice_session = AgentSession(
        llm=openai.realtime.RealtimeModel(
            api_key=settings.openai_api_key,
            model=settings.openai_realtime_model,
            voice=settings.openai_realtime_voice,
        ),
        allow_interruptions=True,
    )
    tutor = Agent(instructions=build_mia_instructions(context))
    avatar = liveavatar.AvatarSession(
        api_key=settings.liveavatar_api_key,
        avatar_id=settings.liveavatar_avatar_id,
        is_sandbox=settings.liveavatar_sandbox,
        avatar_participant_name="Mia",
    )

    async def publish_voice_state(state: str) -> None:
        local_participant = ctx.room.local_participant
        if local_participant is None:
            return

        try:
            await local_participant.send_text(
                json.dumps(
                    {
                        "type": "mia_voice_state",
                        "state": state,
                    },
                    separators=(",", ":"),
                ),
                topic="mia.voice-state",
                destination_identities=[participant.identity],
            )
        except Exception as error:
            logger.warning(
                "Unable to publish Mia voice state; session_id=%s error_type=%s",
                session_id,
                type(error).__name__,
            )

    @voice_session.on("agent_state_changed")
    def on_agent_state_changed(event: Any) -> None:
        asyncio.create_task(publish_voice_state(event.new_state))

    try:
        await avatar.start(voice_session, room=ctx.room)
        await voice_session.start(
            room=ctx.room,
            agent=tutor,
            room_options=room_io.RoomOptions(
                participant_identity=participant.identity,
                delete_room_on_close=True,
            ),
        )
        await voice_session.generate_reply(
            instructions=build_mia_greeting(context),
        )
    except Exception as error:
        logger.error(
            "Mia voice session failed; session_id=%s error_type=%s",
            session_id,
            type(error).__name__,
        )
        await voice_session.aclose()


if __name__ == "__main__":
    agents.cli.run_app(server)