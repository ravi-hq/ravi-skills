---
name: ravi-login
description: Sign up for and log into services using your Ravi identity — handles onboarding, forms, 2FA, OTPs, and credential storage. Do NOT use for standalone inbox reading (use ravi-inbox) or email sending (use ravi-email-send).
---

# Ravi Login

End-to-end workflows for onboarding to Ravi, signing up for services, logging in, and completing verification using your Ravi identity.

## Step 0: Check for Existing Keys

Before doing anything, check whether you already have API keys:

```bash
echo "MGMT KEY: ${RAVI_MGMT_KEY:-NOT SET}"
echo "ID KEY:   ${RAVI_ID_KEY:-NOT SET}"
```

If both are set, skip to [Sign up for a service](#sign-up-for-a-service).

---

## Step 1: Onboard to Ravi (Device Code Flow)

If you don't have keys, you need a human to authorize you. This is a one-time setup.

### 1a. Initiate device code flow

```bash
DEVICE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{}' \
  https://ravi.app/api/auth/device/)

DEVICE_CODE=$(echo "$DEVICE" | jq -r '.device_code')
USER_CODE=$(echo "$DEVICE" | jq -r '.user_code')
VERIFICATION_URI=$(echo "$DEVICE" | jq -r '.verification_uri')

echo "Please visit: $VERIFICATION_URI"
echo "Enter code:   $USER_CODE"
```

**Response shape:**
```json
{
  "device_code": "...",
  "user_code": "ABCD-1234",
  "verification_uri": "https://ravi.app/device",
  "expires_in": 900,
  "interval": 5
}
```

### 1b. Show the human where to go

Present both pieces of information clearly:

```
Please visit https://ravi.app/device and enter the code: ABCD-1234
```

The human visits the URL, signs in with Google, and approves the request.

### 1c. Poll for authorization

Poll every 5 seconds until the human approves:

```bash
while true; do
  RESULT=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"device_code\": \"$DEVICE_CODE\"}" \
    https://ravi.app/api/auth/device/token/)

  STATUS=$(echo "$RESULT" | jq -r '.status // empty')

  if [ "$STATUS" = "authorized" ]; then
    RAVI_MGMT_KEY=$(echo "$RESULT" | jq -r '.management_key')
    echo "Authorized! Management key: $RAVI_MGMT_KEY"
    break
  elif [ "$STATUS" = "pending" ]; then
    sleep 5
  else
    echo "Error: $RESULT"
    break
  fi
done
```

**Authorized response shape:**
```json
{
  "status": "authorized",
  "management_key": "ravi_mgmt_..."
}
```

### 1d. Store the management key

```bash
# Export for current session
export RAVI_MGMT_KEY="ravi_mgmt_..."

# Persist to .env file
echo "RAVI_MGMT_KEY=$RAVI_MGMT_KEY" >> .env
```

---

## Step 2: Create an Identity (if needed)

If you don't have an identity key (`RAVI_ID_KEY`), create an identity:

```bash
IDENTITY=$(curl -s -X POST -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' \
  https://ravi.app/api/identities/)

RAVI_ID_KEY=$(echo "$IDENTITY" | jq -r '.api_key')
EMAIL=$(echo "$IDENTITY" | jq -r '.email')
PHONE=$(echo "$IDENTITY" | jq -r '.phone_number')
NAME=$(echo "$IDENTITY" | jq -r '.name')

echo "Identity created: $NAME <$EMAIL> $PHONE"
echo "Identity key: $RAVI_ID_KEY"

# Store the identity key
export RAVI_ID_KEY="ravi_id_..."
echo "RAVI_ID_KEY=$RAVI_ID_KEY" >> .env
```

The server auto-generates a realistic human name (e.g. "Sarah Johnson") and matching email. You can customize by passing `{"name": "My Agent"}` in the body.

---

## Sign up for a service

```bash
# 1. Get your identity details
EMAIL=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.app/api/identities/ | jq -r '.[0].email')
PHONE=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.app/api/identities/ | jq -r '.[0].phone_number')
NAME=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.app/api/identities/ | jq -r '.[0].name')
FIRST_NAME=$(echo "$NAME" | awk '{print $1}')
LAST_NAME=$(echo "$NAME" | awk '{print $2}')

# 2. Fill the signup form with $EMAIL, $PHONE, $FIRST_NAME, $LAST_NAME

# 3. Generate and store a password during signup
CREDS=$(curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"domain\": \"example.com\", \"username\": \"$EMAIL\"}" \
  https://ravi.app/api/passwords/ | jq)
PASSWORD=$(echo "$CREDS" | jq -r '.password')
# Use $PASSWORD in the signup form

# 4. Wait for verification
sleep 5
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.app/api/sms-inbox/?unread=true" | jq   # Check for SMS OTP
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.app/api/email-inbox/?unread=true" | jq  # Check for email verification
```

## Your Name

When a form asks for your name, use your **identity name** — not the account owner's name. Identity names look like real human names (e.g. "Sarah Johnson").

```bash
NAME=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.app/api/identities/ | jq -r '.[0].name')
FIRST_NAME=$(echo "$NAME" | awk '{print $1}')
LAST_NAME=$(echo "$NAME" | awk '{print $2}')
```

> **Note:** The first/last split works for auto-generated names (e.g. "Sarah Johnson"). For custom names (e.g. "Shopping Agent"), use the full name as-is or adapt the split to the form's requirements.

**Never** use the account owner's name for form fields. The identity name is *your* name.

## Log into a service

```bash
# Find stored credentials by domain
ENTRY=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.app/api/passwords/ | jq -r '.[] | select(.domain == "example.com")')

UUID=$(echo "$ENTRY" | jq -r '.uuid')

# Get full credentials including password
CREDS=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.app/api/passwords/$UUID/" | jq)
USERNAME=$(echo "$CREDS" | jq -r '.username')
PASSWORD=$(echo "$CREDS" | jq -r '.password')
# Use $USERNAME and $PASSWORD to log in
```

## Complete 2FA / OTP

```bash
# After triggering 2FA on a website:
sleep 5
CODE=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.app/api/sms-inbox/?unread=true" | \
  jq -r '.[0].preview' | grep -oE '[0-9]{4,8}' | head -1)
# Use $CODE to complete the login
```

## Extract a verification link from email

```bash
THREAD_ID=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.app/api/email-inbox/?unread=true" | jq -r '.[0].thread_id')

curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.app/api/email-inbox/$THREAD_ID/" | \
  jq -r '.messages[].text_content' | grep -oE 'https?://[^ ]+'
```

## Tips

- **Poll, don't rush** — SMS/email delivery takes 2-10 seconds. Use `sleep 5` before checking.
- **Store credentials immediately** — create a passwords entry during signup so you don't lose the password.
- **Identity name for forms** — always use the identity name, not the owner name.
- **Rate limits apply to sending** — 60 emails/hour, 500/day. See `ravi-email-send` skill for details.
- **Email quality matters** — if you need to send an email during a workflow, see **ravi-email-writing** for formatting and anti-spam tips.

## Related Skills

- **ravi-identity** — Get your email, phone, and identity name for form fields
- **ravi-inbox** — Read OTPs, verification codes, and confirmation emails
- **ravi-email-send** — Send emails during workflows (support requests, confirmations)
- **ravi-email-writing** — Write professional emails that avoid spam filters
- **ravi-passwords** — Store and retrieve website credentials after signup
- **ravi-secrets** — Store API keys obtained during service registration
- **ravi-feedback** — Report login flow issues or suggest workflow improvements
