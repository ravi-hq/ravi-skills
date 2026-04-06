---
name: ravi-login
description: Sign up for and log into services using your Ravi identity — handles onboarding, forms, 2FA, OTPs, and credential storage. Do NOT use for standalone inbox reading (use ravi-inbox) or email sending (use ravi-email-send).
---

# Ravi Login

End-to-end workflows for onboarding to Ravi, signing up for services, logging in, and completing verification using your Ravi identity.

## Step 0: Check for Existing Keys

Before doing anything, check whether you already have API keys:

```bash
RAVI_MGMT_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.management_key // empty')
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')

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
  https://ravi.id/api/auth/device/)

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
  "verification_uri": "https://ravi.id/device",
  "expires_in": 900,
  "interval": 5
}
```

### 1b. Show the human where to go

Present both pieces of information clearly:

```
Please visit https://ravi.id/device and enter the code: ABCD-1234
```

The human visits the URL, signs in with Google, and approves the request.

### 1c. Poll for authorization

Use `wait=true` for long-polling (blocks until the human approves or the code expires):

```bash
RESULT=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"device_code\": \"$DEVICE_CODE\", \"wait\": true}" \
  https://ravi.id/api/auth/device/token/)

# Check for management_key (success) vs error (still pending or expired)
MGMT_KEY=$(echo "$RESULT" | jq -r '.management_key // empty')
if [ -n "$MGMT_KEY" ]; then
  echo "Authorized!"
else
  echo "Error: $(echo "$RESULT" | jq -r '.error_description // .error // "unknown"')"
fi
```

### 1d. Store keys in config files

```bash
# Create ~/.ravi/ directory
mkdir -p ~/.ravi
chmod 700 ~/.ravi

# Save all keys to the global config file
USER_EMAIL=$(echo "$RESULT" | jq -r '.user.email // empty')
ID_KEY=$(echo "$RESULT" | jq -r '.identity_key // empty')
ID_UUID=$(echo "$RESULT" | jq -r '.identity.uuid // empty')
ID_NAME=$(echo "$RESULT" | jq -r '.identity.name // empty')

CONFIG="{\"management_key\": \"$MGMT_KEY\", \"user_email\": \"$USER_EMAIL\""
if [ -n "$ID_KEY" ]; then
  CONFIG="$CONFIG, \"identity_key\": \"$ID_KEY\", \"identity_uuid\": \"$ID_UUID\", \"identity_name\": \"$ID_NAME\""
fi
CONFIG="$CONFIG}"

echo "$CONFIG" > ~/.ravi/config.json
chmod 600 ~/.ravi/config.json
```

---

## Step 2: Select Identity (Returning Users)

If the response has an `identities` list but no `identity_key`, the user already has identities and needs to select one:

```bash
# List identities from response
echo "$RESULT" | jq '.identities'

# Let the user pick, then create an identity key for the selected identity
SELECTED_UUID="<uuid from identities list>"
SELECTED_NAME="<name from identities list>"

ID_KEY_RESP=$(curl -s -X POST -H "Authorization: Bearer $MGMT_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"identity_uuid\": \"$SELECTED_UUID\", \"label\": \"agent\"}" \
  https://ravi.id/api/auth/keys/identity/)

ID_KEY=$(echo "$ID_KEY_RESP" | jq -r '.key')

# Update the global config file with identity key
CONFIG=$(cat ~/.ravi/config.json)
echo "$CONFIG" | jq ". + {\"identity_key\": \"$ID_KEY\", \"identity_uuid\": \"$SELECTED_UUID\", \"identity_name\": \"$SELECTED_NAME\"}" > ~/.ravi/config.json
chmod 600 ~/.ravi/config.json
```

---

## Step 3: Create an Identity (if needed)

If you have a management key but no identities at all, create one:

```bash
RAVI_MGMT_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.management_key // empty')

IDENTITY=$(curl -s -X POST -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' \
  https://ravi.id/api/identities/)

RAVI_ID_KEY=$(echo "$IDENTITY" | jq -r '.api_key')
ID_UUID=$(echo "$IDENTITY" | jq -r '.uuid')
ID_NAME=$(echo "$IDENTITY" | jq -r '.name')
EMAIL=$(echo "$IDENTITY" | jq -r '.email')
PHONE=$(echo "$IDENTITY" | jq -r '.phone_number')

echo "Identity created: $ID_NAME <$EMAIL> $PHONE"

# Save identity key
mkdir -p .ravi
echo "{\"identity_key\": \"$RAVI_ID_KEY\", \"identity_uuid\": \"$ID_UUID\", \"identity_name\": \"$ID_NAME\"}" > .ravi/config.json
chmod 600 .ravi/config.json
```

The server auto-generates a realistic human name (e.g. "Sarah Johnson") and matching email. You can customize by passing `{"name": "My Agent"}` in the body.

---

## Sign up for a service

```bash
# Load keys from config files
RAVI_MGMT_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.management_key // empty')
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')

# 1. Get your identity details
EMAIL=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq -r '.[0].email')
PHONE=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq -r '.[0].phone_number')
NAME=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq -r '.[0].name')
FIRST_NAME=$(echo "$NAME" | awk '{print $1}')
LAST_NAME=$(echo "$NAME" | awk '{print $2}')

# 2. Fill the signup form with $EMAIL, $PHONE, $FIRST_NAME, $LAST_NAME

# 3. Generate and store a password during signup
CREDS=$(curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"domain\": \"example.com\", \"username\": \"$EMAIL\"}" \
  https://ravi.id/api/passwords/ | jq)
PASSWORD=$(echo "$CREDS" | jq -r '.password')
# Use $PASSWORD in the signup form

# 4. Wait for verification
sleep 5
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/sms-inbox/?unread=true" | jq   # Check for SMS OTP
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/email-inbox/?unread=true" | jq  # Check for email verification
```

## Your Name

When a form asks for your name, use your **identity name** — not the account owner's name. Identity names look like real human names (e.g. "Sarah Johnson").

```bash
RAVI_MGMT_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.management_key // empty')

NAME=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq -r '.[0].name')
FIRST_NAME=$(echo "$NAME" | awk '{print $1}')
LAST_NAME=$(echo "$NAME" | awk '{print $2}')
```

> **Note:** The first/last split works for auto-generated names (e.g. "Sarah Johnson"). For custom names (e.g. "Shopping Agent"), use the full name as-is or adapt the split to the form's requirements.

**Never** use the account owner's name for form fields. The identity name is *your* name.

## Log into a service

```bash
# Load identity key
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')

# Find stored credentials by domain
ENTRY=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/passwords/ | jq -r '.[] | select(.domain == "example.com")')

UUID=$(echo "$ENTRY" | jq -r '.uuid')

# Get full credentials including password
CREDS=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/passwords/$UUID/" | jq)
USERNAME=$(echo "$CREDS" | jq -r '.username')
PASSWORD=$(echo "$CREDS" | jq -r '.password')
# Use $USERNAME and $PASSWORD to log in
```

## Complete 2FA / OTP

```bash
# Load identity key
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')

# After triggering 2FA on a website:
sleep 5
CODE=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/sms-inbox/?unread=true" | \
  jq -r '.[0].preview' | grep -oE '[0-9]{4,8}' | head -1)
# Use $CODE to complete the login
```

## Extract a verification link from email

```bash
# Load identity key
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')

THREAD_ID=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/email-inbox/?unread=true" | jq -r '.[0].thread_id')

curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/email-inbox/$THREAD_ID/" | \
  jq -r '.messages[].text_content' | grep -oE 'https?://[^ ]+'
```

## Tips

- **Poll, don't rush** — SMS/email delivery takes 2-10 seconds. Use `sleep 5` before checking.
- **Store credentials immediately** — create a passwords entry during signup so you don't lose the password.
- **Identity name for forms** — always use the identity name, not the owner name.
- **Rate limits apply to sending** — 60 emails/hour, 500/day. See `ravi-email-send` skill for details.
- **Email quality matters** — if you need to send an email during a workflow, see **ravi-email-writing** for formatting and anti-spam tips.


## Full API Reference

For complete endpoint details, request/response schemas, and parameters: [Device Auth](https://ravi.id/docs/schema/device-auth.json) | [Auth & Keys](https://ravi.id/docs/schema/auth.json)

## Related Skills

- **ravi-identity** — Get your email, phone, and identity name for form fields
- **ravi-inbox** — Read OTPs, verification codes, and confirmation emails
- **ravi-email-send** — Send emails during workflows (support requests, confirmations)
- **ravi-email-writing** — Write professional emails that avoid spam filters
- **ravi-passwords** — Store and retrieve website credentials after signup
- **ravi-secrets** — Store API keys obtained during service registration
- **ravi-feedback** — Report login flow issues or suggest workflow improvements
