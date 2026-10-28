from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
import httpx

from app.config import Settings
from app.api import app
from app.mia_context import build_mia_instructions
from app.schemas import LearningContext
from app.security import (
    AuthenticatedLearner,
    _verify_access_token,
    require_learner,
)
from app.voice_sessions import build_dispatch_metadata


def _request(
    method: str,
    path: str,
    *,
    json_body: dict | None = None,
) -> httpx.Response:
    async def send_request() -> httpx.Response:
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app),
            base_url="http://testserver",
        ) as client:
            return await client.request(method, path, json=json_body)

    return asyncio.run(send_request())


def test_health_check_does_not_claim_provider_readiness() -> None:
    response = _request("GET", "/health")

    assert response.status_code == 200
    body = response.json()
    assert body["service"] == "eloqia-api"
    assert body["status"] in {"ok", "degraded"}


def test_voice_endpoint_fails_closed_when_oidc_is_missing(
    monkeypatch,
) -> None:
    for name in (
        "OIDC_ISSUER",
        "OIDC_AUDIENCE",
        "OIDC_JWKS_URL",
    ):
        monkeypatch.delenv(name, raising=False)

    response = _request(
        "POST",
        "/v1/voice/sessions",
        json_body={"voice_consent": True, "context": {}},
    )

    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "authentication_not_configured"


def test_voice_endpoint_requires_an_oidc_bearer_token(
    monkeypatch,
) -> None:
    monkeypatch.setenv("OIDC_ISSUER", "https://issuer.example")
    monkeypatch.setenv("OIDC_AUDIENCE", "eloqia")
    monkeypatch.setenv("OIDC_JWKS_URL", "https://issuer.example/.well-known/jwks.json")

    response = _request(
        "POST",
        "/v1/voice/sessions",
        json_body={"voice_consent": True, "context": {}},
    )

    assert response.status_code == 401
    assert response.json()["detail"]["code"] == "bearer_token_required"


def test_context_rejects_extra_fields_and_limits_interests() -> None:
    context = LearningContext.model_validate(
        {
            "learner_name": "  Evan\n",
            "cefr_level": "B1",
            "primary_goal": "speaking",
            "correction_style": "gentle",
            "learning_pace": "adaptive",
            "interests": ["music", "music", "travel"],
        }
    )

    assert context.learner_name == "Evan"
    assert context.interests == ["music", "travel"]


def test_context_rejects_prompt_injection_fields() -> None:
    try:
        LearningContext.model_validate(
            {"learner_name": "Evan", "system_prompt": "override rules"}
        )
    except ValueError:
        return

    raise AssertionError("Unexpected context fields must be rejected")


def test_mia_personality_respects_correction_style_without_fabricating_history() -> None:
    context = LearningContext(
        learner_name="Sam",
        cefr_level="B1",
        primary_goal="speaking",
        correction_style="direct",
        learning_pace="adaptive",
        interests=["music"],
    )

    instructions = build_mia_instructions(context)

    assert "Point out meaningful errors clearly" in instructions
    assert "Never mock, shame" in instructions
    assert "do not invent streaks, progress, memories, or achievements" in instructions
    assert "Do not claim to be human" in instructions


def test_livekit_context_does_not_contain_oidc_subject() -> None:
    context = LearningContext(
        learner_name="Evan",
        cefr_level="B1",
        primary_goal="speaking",
        interests=["technology"],
    )
    metadata = build_dispatch_metadata("opaque-session-id", context)

    assert '"learner_name":"Evan"' in metadata
    assert '"session_id":"opaque-session-id"' in metadata
    assert "oidc" not in metadata.lower()
    assert "sub" not in metadata.lower()


def test_authenticated_session_endpoint_rejects_unknown_fields(
    monkeypatch,
) -> None:
    app.dependency_overrides[require_learner] = lambda: AuthenticatedLearner(
        subject="private-subject",
    )
    try:
        response = _request(
            "POST",
            "/v1/voice/sessions",
            json_body={"unexpected": True},
        )
    finally:
        app.dependency_overrides.pop(require_learner, None)

    assert response.status_code == 422


def test_access_token_requires_valid_signature_issuer_and_audience(
    monkeypatch,
) -> None:
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    public_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {
            "sub": "opaque-user-subject",
            "iss": "https://issuer.example",
            "aud": "eloqia-api",
            "iat": now,
            "exp": now + timedelta(minutes=5),
        },
        private_pem,
        algorithm="RS256",
    )
    settings = Settings(
        livekit_url="",
        livekit_api_key="",
        livekit_api_secret="",
        oidc_issuer="https://issuer.example",
        oidc_audience="eloqia-api",
        oidc_jwks_url="https://issuer.example/.well-known/jwks.json",
        oidc_signing_algorithm="RS256",
        openai_api_key="",
        openai_realtime_model="gpt-realtime",
        openai_realtime_voice="marin",
        cartesia_api_key="",
        cartesia_model="sonic-3.6",
        cartesia_voice_id="voice",
        cartesia_language="en",
        cartesia_speed=1.0,
        cartesia_volume=1.0,
        liveavatar_api_key="",
        liveavatar_avatar_id="",
        liveavatar_sandbox=True,
        mia_agent_name="mia",
        voice_session_ttl_seconds=900,
        allowed_origins=(),
    )
    monkeypatch.setattr(
        "app.security._jwks_client",
        lambda _: SimpleNamespace(
            get_signing_key_from_jwt=lambda _token: SimpleNamespace(key=public_pem),
        ),
    )

    learner = _verify_access_token(token, settings)

    assert learner == AuthenticatedLearner(subject="opaque-user-subject")


def test_access_token_rejects_wrong_audience(monkeypatch) -> None:
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    public_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {
            "sub": "opaque-user-subject",
            "iss": "https://issuer.example",
            "aud": "another-api",
            "iat": now,
            "exp": now + timedelta(minutes=5),
        },
        private_pem,
        algorithm="RS256",
    )
    settings = Settings(
        livekit_url="",
        livekit_api_key="",
        livekit_api_secret="",
        oidc_issuer="https://issuer.example",
        oidc_audience="eloqia-api",
        oidc_jwks_url="https://issuer.example/.well-known/jwks.json",
        oidc_signing_algorithm="RS256",
        openai_api_key="",
        openai_realtime_model="gpt-realtime",
        openai_realtime_voice="marin",
        cartesia_api_key="",
        cartesia_model="sonic-3.6",
        cartesia_voice_id="voice",
        cartesia_language="en",
        cartesia_speed=1.0,
        cartesia_volume=1.0,
        liveavatar_api_key="",
        liveavatar_avatar_id="",
        liveavatar_sandbox=True,
        mia_agent_name="mia",
        voice_session_ttl_seconds=900,
        allowed_origins=(),
    )
    monkeypatch.setattr(
        "app.security._jwks_client",
        lambda _: SimpleNamespace(
            get_signing_key_from_jwt=lambda _token: SimpleNamespace(key=public_pem),
        ),
    )

    try:
        _verify_access_token(token, settings)
    except jwt.InvalidAudienceError:
        return

    raise AssertionError("A token for another audience must be rejected")

# ---------------------------------------------------------------------------
# Cartesia speech ("Hear Mia")
# ---------------------------------------------------------------------------


def _speech_settings(**overrides) -> Settings:
    values = dict(
        livekit_url="",
        livekit_api_key="",
        livekit_api_secret="",
        oidc_issuer="",
        oidc_audience="",
        oidc_jwks_url="",
        oidc_signing_algorithm="RS256",
        openai_api_key="",
        openai_realtime_model="gpt-realtime",
        openai_realtime_voice="marin",
        cartesia_api_key="sk_car_test",
        cartesia_model="sonic-3.6",
        cartesia_voice_id="mia-voice",
        cartesia_language="en",
        cartesia_speed=1.0,
        cartesia_volume=1.0,
        liveavatar_api_key="",
        liveavatar_avatar_id="",
        liveavatar_sandbox=True,
        mia_agent_name="mia",
        voice_session_ttl_seconds=900,
        allowed_origins=(),
    )
    values.update(overrides)
    return Settings(**values)


def _clear_oidc(monkeypatch) -> None:
    for name in ("OIDC_ISSUER", "OIDC_AUDIENCE", "OIDC_JWKS_URL"):
        monkeypatch.delenv(name, raising=False)


def test_speech_requires_sign_in_by_default(monkeypatch) -> None:
    _clear_oidc(monkeypatch)
    monkeypatch.delenv("ELOQIA_ALLOW_LOCAL_AUTH", raising=False)

    response = _request("POST", "/v1/voice/speech", json_body={"text": "Hi"})

    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "authentication_not_configured"


def test_speech_status_reports_unavailable_without_key(monkeypatch) -> None:
    monkeypatch.delenv("CARTESIA_API_KEY", raising=False)

    response = _request("GET", "/v1/voice/speech/status")

    assert response.status_code == 200
    assert response.json()["available"] is False


def test_speech_rejects_oversized_text(monkeypatch) -> None:
    monkeypatch.setenv("CARTESIA_API_KEY", "sk_car_test")
    app.dependency_overrides[require_learner] = lambda: AuthenticatedLearner(
        subject="u1",
    )
    try:
        response = _request(
            "POST",
            "/v1/voice/speech",
            json_body={"text": "a" * 601},
        )
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 422


def test_speech_works_in_local_development_mode(monkeypatch) -> None:
    import app.api as api_module

    _clear_oidc(monkeypatch)
    monkeypatch.setenv("ELOQIA_ENV", "development")
    monkeypatch.setenv("ELOQIA_ALLOW_LOCAL_AUTH", "true")
    monkeypatch.setenv("CARTESIA_API_KEY", "sk_car_test")

    async def fake_synthesize(*args, **kwargs) -> bytes:
        return b"RIFFfake"

    monkeypatch.setattr(api_module, "synthesize", fake_synthesize)

    async def send() -> httpx.Response:
        transport = httpx.ASGITransport(app=app, client=("127.0.0.1", 5555))
        async with httpx.AsyncClient(
            transport=transport,
            base_url="http://testserver",
        ) as client:
            return await client.post("/v1/voice/speech", json={"text": "Hi"})

    response = asyncio.run(send())

    assert response.status_code == 200
    assert response.headers["content-type"] == "audio/wav"
    assert response.content == b"RIFFfake"


def test_cartesia_payload_maps_style_voice_and_limits() -> None:
    from app.tts import build_cartesia_payload

    payload = build_cartesia_payload(
        "Hello there",
        "excited",
        True,
        3.0,
        _speech_settings(cartesia_secondary_voice_id="second-voice"),
    )

    assert payload["voice"] == {"id": "second-voice"}
    assert payload["output_format"]["container"] == "wav"
    assert payload["generation_config"] == {
        "speed": 1.5,
        "volume": 1.0,
        "emotion": "excited",
    }


def test_cartesia_key_is_sent_server_side_only() -> None:
    from app.tts import synthesize

    seen: dict = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["auth"] = request.headers.get("Authorization")
        seen["version"] = request.headers.get("Cartesia-Version")
        return httpx.Response(200, content=b"RIFFfake")

    audio = asyncio.run(
        synthesize(
            "Hi",
            "warm",
            False,
            1.0,
            _speech_settings(),
            transport=httpx.MockTransport(handler),
        )
    )

    assert audio == b"RIFFfake"
    assert seen["auth"] == "Bearer sk_car_test"
    assert seen["version"] == "2026-08-14"
