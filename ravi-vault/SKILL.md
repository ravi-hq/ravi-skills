---
name: ravi-vault
description: >
  Use when you need to store, retrieve, update, delete, or generate passwords
  and credentials. All fields are E2E encrypted. Do NOT use for reading messages
  (use ravi-inbox) or sending email (use ravi-email-send).
---

# Ravi Vault

Store and retrieve passwords for services you sign up for. All fields are E2E encrypted — the CLI handles encryption/decryption transparently.

## Commands

```bash
# Create entry (auto-generates password if --password not given)
ravi vault create example.com --json
ravi vault create example.com --username "me@ravi.app" --password 'S3cret!' --json

# List all entries
ravi vault list --json

# Retrieve (decrypted)
ravi vault get <uuid> --json

# Update
ravi vault edit <uuid> --password 'NewPass!' --json

# Delete
ravi vault delete <uuid> --json

# Generate a password without storing it
ravi vault generate --length 24 --json
# → {"password": "xK9#mL2..."}
```

**Create flags:** `--username`, `--password`, `--notes`, `--generate`, `--length` (default 16), `--no-special`, `--no-digits`, `--exclude-chars`

## Important Notes

- **E2E encryption is transparent** — the CLI encrypts vault fields before sending and decrypts on retrieval. You see plaintext.
- **Domain cleaning** — `ravi vault create` auto-cleans URLs to base domains (e.g., `https://mail.google.com/inbox` becomes `google.com`).
- **Always use `--json`** — human-readable output is not designed for parsing.
