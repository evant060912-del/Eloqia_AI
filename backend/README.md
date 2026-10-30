# Eloqia Voice Backend

This service is the trusted boundary for authenticated LiveKit voice sessions.
It issues room-scoped participant tokens and dispatches the Mia agent with a
bounded learning context. The OpenAI and LiveAvatar secrets remain on the
server.

## Status

The code is not connected to a provider until the required environment values
are configured. Session creation intentionally returns a service-unavailable
error when OIDC, LiveKit, OpenAI, or LiveAvatar configuration is missing. No
development authentication bypass is provided.

Flutter now has a LiveKit session screen and an API client that requires an
OIDC access-token provider and explicit voice consent. The current Home-to-Mia
route has no OIDC provider injected, and the API URL is unset by default, so a
real session cannot start until both are configured. The UI reports this state
instead of simulating a connected tutor.

## Local setup

From this directory, create a virtual environment and install the pinned direct
dependencies:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Set the OIDC issuer, audience, JWKS URL, LiveKit project credentials, OpenAI
API key, LiveAvatar API key, and avatar ID in `.env`. `LIVEAVATAR_SANDBOX`
defaults to `true`; change it only when a paid production account is ready.
Configure the listed browser origins for local development; production must
use the deployed HTTPS origin.

Run the API and agent in separate terminals:

```powershell
uvicorn app.api:app --reload --host 127.0.0.1 --port 8000
python -m app.agent dev
```

Start Flutter Web with the API URL:

```powershell
flutter run -d chrome --web-port 5000 --dart-define=ELOQIA_API_URL=http://localhost:8000 --dart-define=ELOQIA_VOICE_API_URL=http://localhost:8000
```

The Flutter `MiaScreen` route must also receive an implementation of
`OidcAccessTokenProvider` backed by the product's authenticated sign-in flow.
Do not put a static or long-lived access token in `--dart-define`.

Mia's text routes (OpenAI key required): `POST /v1/mia/chat`,
`POST /v1/mia/chat/summary` and `POST /v1/writing/review` (Writing Studio).
They share one per-learner rate limit.

For local development set `ELOQIA_ENV=development` and
`ELOQIA_ALLOW_LOCAL_AUTH=true`: requests from `127.0.0.1` are accepted without
OIDC, and browsers may call the API from any `localhost` port.

`GET /healthz` is a liveness check and does not imply provider readiness.
Authenticated session creation is exposed at `POST /v1/voice/sessions`.

## Security boundaries

- OIDC bearer tokens are verified against the configured issuer, audience,
  signing algorithm, and JWKS endpoint.
- Participant tokens are short-lived and restricted to one generated room.
- Room/job metadata contains only the validated learning context and an opaque
  session ID; the OIDC subject and bearer token are not forwarded to the agent.
- Do not expose the LiveKit API secret, OpenAI API key, or LiveAvatar API key to
  Flutter Web.
- Configure rate limiting, TLS, secret management, provider retention policy,
  and an authenticated identity provider before deployment.

The current implementation does not provide account registration, durable
conversation storage, learning-memory persistence, progress updates, or
assessment. Those require explicit domain and retention decisions and are not
simulated here.