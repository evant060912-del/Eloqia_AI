from __future__ import annotations

import logging

from fastapi import Depends, FastAPI, HTTPException, status

from app.config import Settings
from app.schemas import LearningContext, VoiceSessionResponse
from app.security import AuthenticatedLearner, require_learner
from app.voice_sessions import create_voice_session


logger = logging.getLogger("eloqia.api")

settings = Settings.from_env()


app = FastAPI(
    title="Eloqia AI API",
    description=(
        "Backend API for Eloqia AI and Mia's realtime "
        "learning experiences."
    ),
    version="1.0.0",
)


# ============================================================================
# SYSTEM
# ============================================================================


@app.get(
    "/health",
    tags=["system"],
)
async def health_check() -> dict[str, object]:
    """
    Return the current backend health state.

    This endpoint intentionally does not require authentication so
    infrastructure and local development tools can verify that the API
    process is alive.
    """

    missing = settings.missing_session_settings()

    if missing:
        return {
            "status": "degraded",
            "service": "eloqia-api",
            "voice_service": "not_ready",
        }

    return {
        "status": "ok",
        "service": "eloqia-api",
        "voice_service": "ready",
    }


# ============================================================================
# VOICE
# ============================================================================


@app.post(
    "/v1/voice/sessions",
    response_model=VoiceSessionResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["voice"],
)
async def create_mia_voice_session(
    context: LearningContext,
    learner: AuthenticatedLearner = Depends(require_learner),
) -> VoiceSessionResponse:
    """
    Create an authenticated realtime voice session with Mia.

    Flow:

        Flutter
           ↓
        Bearer access token
           ↓
        require_learner()
           ↓
        LearningContext validation
           ↓
        LiveKit session creation
           ↓
        Mia agent dispatch
    """

    logger.info(
        "Creating Mia voice session for authenticated learner",
    )

    try:
        return await create_voice_session(
            context=context,
            settings=settings,
        )

    except HTTPException:
        raise

    except Exception:
        logger.exception(
            "Unexpected error while creating Mia voice session",
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