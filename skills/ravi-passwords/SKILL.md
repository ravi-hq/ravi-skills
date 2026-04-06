---
name: ravi-passwords
description: Store and retrieve website credentials — password manager for domain/username/password entries. Do NOT use for API keys/secrets (use ravi-secrets) or reading messages (use ravi-inbox).
---

# Ravi Passwords

Store and retrieve passwords for services you sign up for. All credential fields (username, password, notes) are server-side encrypted — you send and receive plaintext.

All password endpoints use the identity key:
```bash
-H "Authorization: Bearer $RAVI_ID_KEY"
```

## Commands

```bash
# Create entry (auto-generates password if password not given)
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com"}' \
  https://ravi.id/api/passwords/ | jq

# Create with username and password
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com", "username": "me@example.com", "password": "S3cret!"}' \
  https://ravi.id/api/passwords/ | jq

# List all entries
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/passwords/ | jq

# Retrieve a specific entry by UUID
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/passwords/<uuid>/ | jq

# Update an entry
curl -s -X PATCH -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"password": "NewPass!"}' \
  https://ravi.id/api/passwords/<uuid>/ | jq

# Delete an entry
curl -s -X DELETE -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/passwords/<uuid>/

# Generate a password without storing it
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/passwords/generate-password/ | jq
# → {"password": "xK9#mL2..."}

# Generate with options
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/passwords/generate-password/?length=24" | jq
```

**Create body fields:** `domain` (required), `username`, `password`, `notes`

If `password` is omitted, the server auto-generates a strong password.

## JSON Shapes

**`GET /api/passwords/`:**
```json
[
  {
    "uuid": "uuid",
    "domain": "example.com",
    "username": "me@example.com",
    "created_dt": "2026-02-25T10:30:00Z"
  }
]
```

**`GET /api/passwords/<uuid>/`:**
```json
{
  "uuid": "uuid",
  "domain": "example.com",
  "username": "me@example.com",
  "password": "S3cret!",
  "notes": "",
  "created_dt": "2026-02-25T10:30:00Z"
}
```

## Common Patterns

### Sign up for a service — store credentials immediately

```bash
# Generate and store credentials during signup
CREDS=$(curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com", "username": "me@example.com"}' \
  https://ravi.id/api/passwords/ | jq)

PASSWORD=$(echo "$CREDS" | jq -r '.password')
# Use $PASSWORD in the signup form
```

### Log into a service — retrieve stored credentials

```bash
# Find entry by domain
ENTRY=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/passwords/ | jq -r '.[] | select(.domain == "example.com")')

UUID=$(echo "$ENTRY" | jq -r '.uuid')

# Get full credentials including password
CREDS=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/passwords/$UUID/" | jq)

USERNAME=$(echo "$CREDS" | jq -r '.username')
PASSWORD=$(echo "$CREDS" | jq -r '.password')
```

## Important Notes

- **Server-side encryption is transparent** — you always see plaintext values.
- **Domain cleaning** — pass the bare domain (e.g., `example.com`), not a full URL. The server normalizes it.
- **Password in list response** — the list endpoint omits `password` for brevity. Use the detail endpoint (`GET /api/passwords/<uuid>/`) to retrieve the password.

## Related Skills

- **ravi-secrets** — Store API keys and env vars (key-value secrets, not website credentials)
- **ravi-login** — End-to-end signup/login workflows that store credentials here
- **ravi-identity** — Get your email address for the username field
- **ravi-feedback** — Report password manager issues or suggest improvements
