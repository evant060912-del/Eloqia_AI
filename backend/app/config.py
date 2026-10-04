from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parents[1] / ".env", override=False)


def _value(name: str, default: str = "") -> str:
    return os.getenv(name, default).strip()


def _enabled(name: str, default: bool) -> bool:
    value = _value(name, "true" if default else "false").lower()
    return value in {"1", "true", "yes", "on"}


@dataclass(frozen=True, slots=True)
class Settings:
    livekit_url: str
    livekit_api_key: str
    livekit_api_secret: str
    oidc_issuer: str
    oidc_audience: str
    oidc_jwks_url: str
    oidc_signing_algorithm: str
    openai_api_key: str
    liveavatar_api_key: str
    liveavatar_avatar_id: str
    liveavatar_sandbox: bool
    openai_realtime_model: str
    openai_realtime_voice: str
    mia_agent_name: str
    voice_session_ttl_seconds: int
    allowed_origins: tuple[str, ...]

    @classmethod
    def from_env(cls) -> Settings:
        try:
            ttl = int(_value("VOICE_SESSION_TTL_SECONDS", "900"))
        except ValueError:
            ttl = 0

        origins = tuple(
            origin.strip()
            for origin in _value("ALLOWED_ORIGINS").split(",")
            if origin.strip()
        )

        return cls(
            livekit_url=_value("LIVEKIT_URL").rstrip("/"),
            livekit_api_key=_value("LIVEKIT_API_KEY"),
            livekit_api_secret=_value("LIVEKIT_API_SECRET"),
            oidc_issuer=_value("OIDC_ISSUER").rstrip("/"),
            oidc_audience=_value("OIDC_AUDIENCE"),
            oidc_jwks_url=_value("OIDC_JWKS_URL"),
            oidc_signing_algorithm=_value(
                "OIDC_SIGNING_ALGORITHM",
                "RS256",
            ),
            openai_api_key=_value("OPENAI_API_KEY"),
            liveavatar_api_key=_value("LIVEAVATAR_API_KEY"),
            liveavatar_avatar_id=_value("LIVEAVATAR_AVATAR_ID"),
            liveavatar_sandbox=_enabled("LIVEAVATAR_SANDBOX", True),
            openai_realtime_model=_value(
                "OPENAI_REALTIME_MODEL",
                "gpt-realtime",
            ),
            openai_realtime_voice=_value(
                "OPENAI_REALTIME_VOICE",
                "marin",
            ),
            mia_agent_name=_value("MIA_AGENT_NAME", "mia"),
            voice_session_ttl_seconds=ttl,
            allowed_origins=origins,
        )

    def missing_oidc_settings(self) -> list[str]:
        required = {
            "OIDC_ISSUER": self.oidc_issuer,
            "OIDC_AUDIENCE": self.oidc_audience,
            "OIDC_JWKS_URL": self.oidc_jwks_url,
        }
        return [name for name, value in required.items() if not value]

    def missing_session_settings(self) -> list[str]:
        required = {
            "LIVEKIT_URL": self.livekit_url,
            "LIVEKIT_API_KEY": self.livekit_api_key,
            "LIVEKIT_API_SECRET": self.livekit_api_secret,
            "OPENAI_API_KEY": self.openai_api_key,
            "LIVEAVATAR_API_KEY": self.liveavatar_api_key,
            "LIVEAVATAR_AVATAR_ID": self.liveavatar_avatar_id,
        }
        missing = [name for name, value in required.items() if not value]

        if not 60 <= self.voice_session_ttl_seconds <= 3600:
            missing.append("VOICE_SESSION_TTL_SECONDS (must be 60..3600)")

        return missing

    def missing_agent_settings(self) -> list[str]:
        required = {
            "LIVEAVATAR_API_KEY": self.liveavatar_api_key,
            "LIVEAVATAR_AVATAR_ID": self.liveavatar_avatar_id,
            "OPENAI_API_KEY": self.openai_api_key,
        }
        return [name for name, value in required.items() if not value]