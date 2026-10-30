from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


load_dotenv(
    Path(__file__).resolve().parents[1] / ".env",
    override=False,
)


def _value(name: str, default: str = "") -> str:
    return os.getenv(name, default).strip()


def _enabled(name: str, default: bool) -> bool:
    value = _value(
        name,
        "true" if default else "false",
    ).lower()

    return value in {
        "1",
        "true",
        "yes",
        "on",
    }


def _integer(name: str, default: int) -> int:
    try:
        return int(_value(name, str(default)))
    except ValueError:
        return default


def _float(name: str, default: float) -> float:
    try:
        return float(_value(name, str(default)))
    except ValueError:
        return default


@dataclass(frozen=True, slots=True)
class Settings:
    # ------------------------------------------------------------------
    # LiveKit
    # ------------------------------------------------------------------

    livekit_url: str
    livekit_api_key: str
    livekit_api_secret: str

    # ------------------------------------------------------------------
    # OIDC
    # ------------------------------------------------------------------

    oidc_issuer: str
    oidc_audience: str
    oidc_jwks_url: str
    oidc_signing_algorithm: str

    # ------------------------------------------------------------------
    # OpenAI
    # ------------------------------------------------------------------

    openai_api_key: str
    openai_realtime_model: str
    openai_realtime_voice: str

    # ------------------------------------------------------------------
    # Cartesia
    # ------------------------------------------------------------------

    cartesia_api_key: str
    cartesia_model: str
    cartesia_voice_id: str
    cartesia_language: str
    cartesia_speed: float
    cartesia_volume: float

    # ------------------------------------------------------------------
    # LiveAvatar
    #
    # Kept for the future visual/avatar layer.
    # It is intentionally NOT required for voice sessions.
    # ------------------------------------------------------------------

    liveavatar_api_key: str
    liveavatar_avatar_id: str
    liveavatar_sandbox: bool

    # ------------------------------------------------------------------
    # Mia
    # ------------------------------------------------------------------

    mia_agent_name: str

    # ------------------------------------------------------------------
    # Session
    # ------------------------------------------------------------------

    voice_session_ttl_seconds: int
    allowed_origins: tuple[str, ...]

    # ------------------------------------------------------------------
    # Short speech ("Hear Mia" buttons)
    # ------------------------------------------------------------------

    cartesia_api_version: str = "2026-08-14"
    cartesia_secondary_voice_id: str = ""

    # ------------------------------------------------------------------
    # Mia chat ("cerveau" de Mia, mode tour par tour)
    # ------------------------------------------------------------------

    openai_chat_model: str = "gpt-5.4-mini"
    mia_chat_max_per_window: int = 30
    mia_chat_window_seconds: int = 600
    mia_chat_max_per_day: int = 200

    @classmethod
    def from_env(cls) -> Settings:
        origins = tuple(
            origin.strip()
            for origin in _value("ALLOWED_ORIGINS").split(",")
            if origin.strip()
        )

        return cls(
            # LiveKit
            livekit_url=_value("LIVEKIT_URL").rstrip("/"),
            livekit_api_key=_value("LIVEKIT_API_KEY"),
            livekit_api_secret=_value("LIVEKIT_API_SECRET"),

            # OIDC
            oidc_issuer=_value("OIDC_ISSUER").rstrip("/"),
            oidc_audience=_value("OIDC_AUDIENCE"),
            oidc_jwks_url=_value("OIDC_JWKS_URL"),
            oidc_signing_algorithm=_value(
                "OIDC_SIGNING_ALGORITHM",
                "RS256",
            ),

            # OpenAI
            openai_api_key=_value("OPENAI_API_KEY"),
            openai_realtime_model=_value(
                "OPENAI_REALTIME_MODEL",
                "gpt-realtime",
            ),
            openai_realtime_voice=_value(
                "OPENAI_REALTIME_VOICE",
                "marin",
            ),

            # Cartesia
            cartesia_api_key=_value("CARTESIA_API_KEY"),
            cartesia_model=_value(
                "CARTESIA_MODEL",
                "sonic-3.6",
            ),
            cartesia_voice_id=_value(
                "CARTESIA_VOICE_ID",
                "b7d50908-b17c-442d-ad8d-810c63997ed9",
            ),
            cartesia_language=_value(
                "CARTESIA_LANGUAGE",
                "en",
            ),
            cartesia_speed=_float(
                "CARTESIA_SPEED",
                1.0,
            ),
            cartesia_volume=_float(
                "CARTESIA_VOLUME",
                1.0,
            ),

            # LiveAvatar
            #
            # These remain available for the future avatar layer,
            # but are not required by the current voice architecture.
            liveavatar_api_key=_value(
                "LIVEAVATAR_API_KEY",
            ),
            liveavatar_avatar_id=_value(
                "LIVEAVATAR_AVATAR_ID",
            ),
            liveavatar_sandbox=_enabled(
                "LIVEAVATAR_SANDBOX",
                True,
            ),

            # Mia
            mia_agent_name=_value(
                "MIA_AGENT_NAME",
                "mia",
            ),

            # Session
            voice_session_ttl_seconds=_integer(
                "VOICE_SESSION_TTL_SECONDS",
                900,
            ),
            allowed_origins=origins,
            cartesia_api_version=_value(
                "CARTESIA_API_VERSION",
                "2026-08-14",
            ),
            cartesia_secondary_voice_id=_value(
                "CARTESIA_SECONDARY_VOICE_ID",
            ),
            openai_chat_model=_value(
                "OPENAI_CHAT_MODEL",
                "gpt-5.4-mini",
            ),
            mia_chat_max_per_window=_integer(
                "MIA_CHAT_MAX_PER_WINDOW",
                30,
            ),
            mia_chat_window_seconds=_integer(
                "MIA_CHAT_WINDOW_SECONDS",
                600,
            ),
            mia_chat_max_per_day=_integer(
                "MIA_CHAT_MAX_PER_DAY",
                200,
            ),
        )

    # ------------------------------------------------------------------
    # Validation
    # ------------------------------------------------------------------

    @staticmethod
    def local_origin_regex() -> str | None:
        """Any localhost port, only in local development with local auth.

        Same switches as `security._is_local_development_request`.
        """
        development = _value("ELOQIA_ENV", "production").lower() == "development"
        local_auth = _value("ELOQIA_ALLOW_LOCAL_AUTH", "false").lower() == "true"
        if development and local_auth:
            return r"http://(localhost|127\.0\.0\.1)(:\d+)?"
        return None

    def missing_oidc_settings(self) -> list[str]:
        required = {
            "OIDC_ISSUER": self.oidc_issuer,
            "OIDC_AUDIENCE": self.oidc_audience,
            "OIDC_JWKS_URL": self.oidc_jwks_url,
        }

        return [
            name
            for name, value in required.items()
            if not value
        ]

    def missing_session_settings(self) -> list[str]:
        required = {
            "LIVEKIT_URL": self.livekit_url,
            "LIVEKIT_API_KEY": self.livekit_api_key,
            "LIVEKIT_API_SECRET": self.livekit_api_secret,
            "OPENAI_API_KEY": self.openai_api_key,
            "CARTESIA_API_KEY": self.cartesia_api_key,
            "CARTESIA_MODEL": self.cartesia_model,
            "CARTESIA_VOICE_ID": self.cartesia_voice_id,
            "MIA_AGENT_NAME": self.mia_agent_name,
        }

        missing = [
            name
            for name, value in required.items()
            if not value
        ]

        if not 60 <= self.voice_session_ttl_seconds <= 3600:
            missing.append(
                "VOICE_SESSION_TTL_SECONDS (must be 60..3600)"
            )

        if not 0.6 <= self.cartesia_speed <= 2.0:
            missing.append(
                "CARTESIA_SPEED (must be 0.6..2.0)"
            )

        if not 0.5 <= self.cartesia_volume <= 2.0:
            missing.append(
                "CARTESIA_VOLUME (must be 0.5..2.0)"
            )

        return missing

    def missing_agent_settings(self) -> list[str]:
        required = {
            "LIVEKIT_URL": self.livekit_url,
            "LIVEKIT_API_KEY": self.livekit_api_key,
            "LIVEKIT_API_SECRET": self.livekit_api_secret,
            "OPENAI_API_KEY": self.openai_api_key,
            "CARTESIA_API_KEY": self.cartesia_api_key,
            "CARTESIA_MODEL": self.cartesia_model,
            "CARTESIA_VOICE_ID": self.cartesia_voice_id,
            "MIA_AGENT_NAME": self.mia_agent_name,
        }

        missing = [
            name
            for name, value in required.items()
            if not value
        ]

        if not 0.6 <= self.cartesia_speed <= 2.0:
            missing.append(
                "CARTESIA_SPEED (must be 0.6..2.0)"
            )

        if not 0.5 <= self.cartesia_volume <= 2.0:
            missing.append(
                "CARTESIA_VOLUME (must be 0.5..2.0)"
            )

        return missing