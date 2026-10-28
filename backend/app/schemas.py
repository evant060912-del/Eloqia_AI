from __future__ import annotations

import re
from typing import Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    field_validator,
)


# ============================================================
# LEARNING CONTEXT
# Stores the learner information Mia needs to personalize
# a voice session.
# ============================================================

class LearningContext(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True,
    )

    learner_name: str | None = Field(
        default=None,
        max_length=48,
    )

    cefr_level: Literal[
        "A1",
        "A2",
        "B1",
        "B2",
        "C1",
        "C2",
    ] = "A1"

    primary_goal: Literal[
        "speaking",
        "school",
        "travel",
        "fluency",
        "academic",
        "career",
        "culture",
    ] | None = None

    correction_style: Literal[
        "gentle",
        "balanced",
        "direct",
        "deep",
    ] = "balanced"

    learning_pace: Literal[
        "relaxed",
        "regular",
        "intensive",
        "adaptive",
    ] = "adaptive"

    interests: list[
        Literal[
            "technology",
            "music",
            "movies",
            "gaming",
            "science",
            "travel",
            "sports",
            "business",
            "history",
            "art",
            "psychology",
            "space",
        ]
    ] = Field(
        default_factory=list,
        max_length=8,
    )

    @field_validator("learner_name")
    @classmethod
    def reject_blank_optional_text(
        cls,
        value: str | None,
    ) -> str | None:
        if value is None:
            return None

        normalized = re.sub(
            r"[\x00-\x1f\x7f]",
            " ",
            value,
        ).strip()

        return normalized or None

    @field_validator("interests")
    @classmethod
    def deduplicate_interests(
        cls,
        values: list[str],
    ) -> list[str]:
        return list(dict.fromkeys(values))[:8]


# ============================================================
# VOICE SESSION REQUEST
# Defines the payload Flutter must send to the API.
# ============================================================

class VoiceSessionRequest(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
    )

    voice_consent: bool

    context: LearningContext = Field(
        default_factory=LearningContext,
    )


# ============================================================
# VOICE SESSION RESPONSE
# Contains the connection information Flutter needs.
# ============================================================

class VoiceSessionResponse(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
    )

    session_id: str

    room_name: str

    livekit_url: str

    participant_token: str

    expires_in_seconds: int = Field(
        gt=0,
    )

class SpeechRequest(BaseModel):
    """One short line spoken by Mia (or another speaker in a dialogue)."""

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    text: str = Field(min_length=1, max_length=600)
    style: Literal[
        "warm",
        "excited",
        "encouraging",
        "playful",
        "serious",
        "calm",
    ] = "warm"
    other_speaker: bool = False
    speed_factor: float = Field(default=1.0, ge=0.5, le=2.0)
