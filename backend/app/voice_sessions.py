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

logger = logging.getLogger(__name__)


def build_dispatch_metadata(
    session_id: str,
    context: LearningContext,
) -> str:
    return json.dumps(
        {
            "schema_version": 1,
            "session_id": session_id,
            "context": context.model_dump(mode="json"),
        },
        separators=(",", ":"),
    )


async def create_voice_session(
    context: LearningContext,
    settings: Settings,
) -> VoiceSessionResponse:
    missing = settings.missing_session_settings()
    if missing:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "code": "voice_provider_not_configured",
                "missing_configuration": missing,
            },
        )

    session_id = str(uuid4())
    room_name = f"eloqia-mia-{secrets.token_urlsafe(18).lower()}"
    participant_identity = f"learner-{secrets.token_urlsafe(12).lower()}"

    job_metadata = build_dispatch_metadata(session_id, context)

    token = (
        api.AccessToken(
            api_key=settings.livekit_api_key,
            api_secret=settings.livekit_api_secret,
        )
        .with_identity(participant_identity)
        .with_name("Learner")
        .with_ttl(timedelta(seconds=settings.voice_session_ttl_seconds))
        .with_grants(
            api.VideoGrants(
                room_join=True,
                room=room_name,
                can_publish=True,
                can_subscribe=True,
                can_publish_data=True,
            )
        )
        .to_jwt()
    )

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
                )
            )
    except Exception as error:
        logger.error(
            "Mia session dispatch failed; session_id=%s error_type=%s",
            session_id,
            type(error).__name__,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "voice_session_unavailable"},
        ) from None

    return VoiceSessionResponse(
        session_id=session_id,
        room_name=room_name,
        livekit_url=settings.livekit_url,
        participant_token=token,
        expires_in_seconds=settings.voice_session_ttl_seconds,
    )