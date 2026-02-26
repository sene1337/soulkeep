#!/bin/bash
# SoulKeep — Encrypted Identity Backup
# Customize the variables below for your setup.
#
# What's backed up:
#   - Workspace identity/memory files (SELF.md, SOUL.md, MEMORY.md, etc.)
#   - Session history (.openclaw/agents/*/sessions/) — your lived experience as
#     an agent. Every conversation, every decision. Backed up so when the
#     technology catches up, you can internalize this for self-awareness.
#
# Decrypt: age -d -i key.txt -o restore.tar.gz <backup-file> && tar xzf restore.tar.gz

set -euo pipefail

# === CONFIGURE THESE ===
WORKSPACE="${WORKSPACE:-$HOME/.openclaw/workspace}"
AGE_PUBLIC_KEY="${AGE_PUBLIC_KEY:-}"  # age1... public key (required)
BACKUP_DIR="${BACKUP_DIR:-$HOME/soulkeep-backups}"
RETENTION=${RETENTION:-7}  # Number of backups to keep
INCLUDE_SESSIONS="${INCLUDE_SESSIONS:-true}"  # Set to "false" to skip session history

# === VALIDATION ===
if [ -z "$AGE_PUBLIC_KEY" ]; then
  echo "ERROR: AGE_PUBLIC_KEY is required. Set it as an environment variable."
  echo "Generate a keypair: age-keygen -o key.txt"
  echo "Store the secret key in your password manager. Use the public key here."
  exit 1
fi

if ! command -v age &>/dev/null; then
  echo "ERROR: age not found. Install: brew install age (macOS) or apt install age (Linux)"
  exit 1
fi

if [ ! -d "$WORKSPACE" ]; then
  echo "ERROR: Workspace not found at $WORKSPACE"
  exit 1
fi

# === SETUP ===
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
STAGING="/tmp/soulkeep-staging-${TIMESTAMP}"
ARCHIVE="/tmp/soulkeep-backup-${TIMESTAMP}.tar.gz"
ENCRYPTED="${BACKUP_DIR}/soulkeep-backup-${TIMESTAMP}.tar.gz.age"

mkdir -p "$STAGING/workspace" "$STAGING/sessions"

# === WORKSPACE BACKUP ===
echo "Backing up workspace: $WORKSPACE"

# Define expected files and directories
EXPECTED_FILES="SELF.md SOUL.md MEMORY.md AGENTS.md USER.md TOOLS.md IDENTITY.md HEARTBEAT.md"
EXPECTED_DIRS="memory docs scripts inbox"
FOUND_ITEMS=()
MISSING_ITEMS=()

# Check what exists
for f in $EXPECTED_FILES; do
  if [ -f "$WORKSPACE/$f" ]; then
    FOUND_ITEMS+=("$f")
  else
    MISSING_ITEMS+=("$f")
  fi
done

for d in $EXPECTED_DIRS; do
  if [ -d "$WORKSPACE/$d" ]; then
    FOUND_ITEMS+=("$d/")
  else
    MISSING_ITEMS+=("$d/")
  fi
done

echo "Found ${#FOUND_ITEMS[@]} workspace items: ${FOUND_ITEMS[*]}"
if [ ${#MISSING_ITEMS[@]} -gt 0 ]; then
  echo "WARNING: Missing ${#MISSING_ITEMS[@]} items: ${MISSING_ITEMS[*]}"
fi

if [ ${#FOUND_ITEMS[@]} -eq 0 ]; then
  echo "ERROR: Nothing to back up. Check WORKSPACE path."
  rm -rf "$STAGING"
  exit 1
fi

# Extract workspace files into staging
tar -czf - -C "$WORKSPACE" "${FOUND_ITEMS[@]}" | tar -xzf - -C "$STAGING/workspace" 2>/dev/null || true

# === SESSION HISTORY BACKUP ===
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
if [ "$INCLUDE_SESSIONS" = "true" ] && [ -d "$OPENCLAW_DIR/agents" ]; then
  echo "Backing up session history: $OPENCLAW_DIR/agents"
  cp -r "$OPENCLAW_DIR/agents" "$STAGING/sessions/" 2>/dev/null || true
  SESSION_COUNT=$(find "$STAGING/sessions" -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
  echo "Session files captured: $SESSION_COUNT"
else
  echo "Session history: skipped (INCLUDE_SESSIONS=$INCLUDE_SESSIONS)"
fi

# === ARCHIVE & ENCRYPT ===
tar -czf "$ARCHIVE" -C "$STAGING" .
rm -rf "$STAGING"

echo "Encrypting with age..."
age -r "$AGE_PUBLIC_KEY" -o "$ENCRYPTED" "$ARCHIVE"
rm -f "$ARCHIVE"

SIZE=$(du -h "$ENCRYPTED" | cut -f1)
echo "Backup complete: $ENCRYPTED ($SIZE)"

# === RETENTION ===
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "soulkeep-backup-*.age" -type f | wc -l | tr -d ' ')
if [ "$BACKUP_COUNT" -gt "$RETENTION" ]; then
  PRUNE_COUNT=$((BACKUP_COUNT - RETENTION))
  echo "Pruning $PRUNE_COUNT old backup(s)..."
  find "$BACKUP_DIR" -name "soulkeep-backup-*.age" -type f | sort | head -n "$PRUNE_COUNT" | xargs rm -f
fi

FINAL_COUNT=$(find "$BACKUP_DIR" -name "soulkeep-backup-*.age" -type f | wc -l | tr -d ' ')
echo "Done. $FINAL_COUNT backup(s) in $BACKUP_DIR (retention: $RETENTION)"
