from __future__ import annotations

import asyncio
import os
from dataclasses import dataclass
from functools import lru_cache

import jwt
from fastapi import Header, HTTPException, Request, status
from jwt import PyJWKClient
from jwt.exceptions import PyJWKClientError, PyJWTError

from app.config import Settings


@dataclass(frozen=True, slots=True)
class AuthenticatedLearner:
    subject: str


@lru_cache(maxsize=4)
def _jwks_client(url: str) -> PyJWKClient:
    return PyJWKClient(url, cache_keys=True)


def _verify_access_token(
    token: str,
    settings: Settings,
) -> AuthenticatedLearner:
    signing_key = _jwks_client(
        settings.oidc_jwks_url,
    ).get_signing_key_from_jwt(token)

    claims = jwt.decode(
        token,
        signing_key.key,
        algorithms=[settings.oidc_signing_algorithm],
        audience=settings.oidc_audience,
        issuer=settings.oidc_issuer,
        options={"require": ["exp", "iat", "sub"]},
    )

    subject = claims.get("sub")

    if (
        not isinstance(subject, str)
        or not subject.strip()
        or len(subject) > 255
    ):
        raise PyJWTError("Invalid subject claim")

    return AuthenticatedLearner(subject=subject)


def _is_local_development_request(request: Request) -> bool:
    environment = os.getenv(
        "ELOQIA_ENV",
        "production",
    ).strip().lower()

    enabled = os.getenv(
        "ELOQIA_ALLOW_LOCAL_AUTH",
        "false",
    ).strip().lower() == "true"

    client_host = (
        request.client.host
        if request.client is not None
        else ""
    )

    return (
        environment == "development"
        and enabled
        and client_host in {"127.0.0.1", "::1"}
    )


async def require_learner(
    request: Request,
    authorization: str | None = Header(default=None),
) -> AuthenticatedLearner:
    settings = Settings.from_env()

    if settings.missing_oidc_settings():
        if _is_local_development_request(request):
            return AuthenticatedLearner(
                subject="local-development-learner",
            )

        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "code": "authentication_not_configured",
                "message": (
                    "OIDC authentication is not configured."
                ),
            },
        )

    if (
        authorization is None
        or not authorization.startswith("Bearer ")
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "bearer_token_required"},
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = authorization.removeprefix("Bearer ").strip()

    if not token or len(token) > 8192:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_bearer_token"},
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        learner = await asyncio.to_thread(
            _verify_access_token,
            token,
            settings,
        )
    except (PyJWTError, PyJWKClientError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_bearer_token"},
            headers={"WWW-Authenticate": "Bearer"},
        ) from None

    return learner