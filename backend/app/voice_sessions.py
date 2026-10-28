from __future__ import annotations

import json
import logging
import secrets
from datetime import timedelta
from uuid import uuid4

from fastapi import HTTPException, status
from livekit import api

from app.config import Settings
from app.schemas import LearningContext, VoiceSessionResponse


logger = logging.getLogger("eloqia.voice_sessions")


def build_dispatch_metadata(
    session_id: str,
    context: LearningContext,
) -> str:
    """
    Build the versioned metadata consumed by Mia's LiveKit agent.

    Only non-secret learning context is sent to the agent.
    Provider credentials always remain server-side.
    """

    payload = {
        "schema_version": 1,
        "session_id": session_id,
        "context": context.model_dump(mode="json"),
    }

    return json.dumps(
        payload,
        separators=(",", ":"),
    )


def _raise_configuration_error(
    missing: list[str],
) -> None:
    """
    Fail closed when the voice backend is not fully configured.

    This prevents Flutter from receiving a valid LiveKit session
    for a backend that cannot actually start Mia.
    """

    if not missing:
        return

    logger.error(
        "Voice service configuration incomplete; missing=%s",
        ", ".join(missing),
    )

    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail={
            "code": "voice_provider_not_configured",
            "missing_configuration": missing,
        },
    )


async def create_voice_session(
    context: LearningContext,
    settings: Settings,
) -> VoiceSessionResponse:
    """
    Create a secure LiveKit session for a learner talking with Mia.

    Flow:

        Flutter
          ↓
        authenticated API request
          ↓
        configuration validation
          ↓
        LiveKit room creation
          ↓
        Mia agent dispatch
          ↓
        participant token
          ↓
        Flutter joins LiveKit
    """

    # ------------------------------------------------------------------
    # 1. Validate the complete server-side voice stack
    # ------------------------------------------------------------------

    missing = settings.missing_session_settings()

    _raise_configuration_error(missing)

    # ------------------------------------------------------------------
    # 2. Generate isolated identifiers
    # ------------------------------------------------------------------

    session_id = str(uuid4())

    room_name = (
        "eloqia-mia-"
        f"{secrets.token_urlsafe(18).lower()}"
    )

    participant_identity = (
        "learner-"
        f"{secrets.token_urlsafe(12).lower()}"
    )

    # ------------------------------------------------------------------
    # 3. Build agent metadata
    # ------------------------------------------------------------------

    job_metadata = build_dispatch_metadata(
        session_id=session_id,
        context=context,
    )

    # ------------------------------------------------------------------
    # 4. Generate the learner's LiveKit token
    # ------------------------------------------------------------------

    token = (
        api.AccessToken(
            api_key=settings.livekit_api_key,
            api_secret=settings.livekit_api_secret,
        )
        .with_identity(participant_identity)
        .with_name("Learner")
        .with_ttl(
            timedelta(
                seconds=settings.voice_session_ttl_seconds,
            ),
        )
        .with_grants(
            api.VideoGrants(
                room_join=True,
                room=room_name,
                can_publish=True,
                can_subscribe=True,
                can_publish_data=True,
            ),
        )
        .to_jwt()
    )

    # ------------------------------------------------------------------
    # 5. Dispatch Mia's agent to the dedicated room
    # ------------------------------------------------------------------

    try:
        async with api.LiveKitAPI(
            url=settings.livekit_url,
            api_key=settings.livekit_api_key,
            api_secret=settings.livekit_api_secret,
        ) as livekit_api:
            await livekit_api.agent_dispatch.create_dispatch(
                api.CreateAgentDispatchRequest(
                    agent_name=settings.mia_agent_name,
                    room=room_name,
                    metadata=job_metadata,
                ),
            )

    except Exception as error:
        logger.error(
            "Mia agent dispatch failed; "
            "session_id=%s error_type=%s",
            session_id,
            type(error).__name__,
        )

        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "code": "voice_session_unavailable",
                "message": (
                    "The Mia voice service is temporarily "
                    "unavailable."
                ),
            },
        ) from None

    # ------------------------------------------------------------------
    # 6. Return only what the Flutter client needs
    # ------------------------------------------------------------------

    logger.info(
        "Mia voice session created; "
        "session_id=%s room=%s agent=%s",
        session_id,
        room_name,
        settings.mia_agent_name,
    )

    return VoiceSessionResponse(
        session_id=session_id,
        room_name=room_name,
        livekit_url=settings.livekit_url,
        participant_token=token,
        expires_in_seconds=(
            settings.voice_session_ttl_seconds
        ),
    )