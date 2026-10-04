from __future__ import annotations

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from app.config import Settings
from app.schemas import VoiceSessionRequest, VoiceSessionResponse
from app.security import AuthenticatedLearner, require_learner
from app.voice_sessions import create_voice_session

app = FastAPI(
    title="Eloqia Voice API",
    version="0.1.0",
    docs_url="/docs",
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(Settings.from_env().allowed_origins),
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)


@app.get("/healthz", include_in_schema=False)
async def health_check() -> dict[str, str]:
    return {"status": "ok", "service": "eloqia-voice-api"}


@app.post(
    "/v1/voice/sessions",
    response_model=VoiceSessionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def start_voice_session(
    payload: VoiceSessionRequest,
    learner: AuthenticatedLearner = Depends(require_learner),
) -> VoiceSessionResponse:
    if not payload.voice_consent:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "voice_consent_required"},
        )

    if not learner.subject:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_bearer_token"},
        )

    return await create_voice_session(
        payload.context,
        Settings.from_env(),
    )