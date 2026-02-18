#!/bin/bash
# Digital Citadel — Encrypted Identity Backup
# Customize the variables below for your setup.

set -euo pipefail

# === CONFIGURE THESE ===
WORKSPACE="${WORKSPACE:-$HOME/.openclaw/workspace}"
AGE_PUBLIC_KEY="${AGE_PUBLIC_KEY:-}"  # age1... public key (required)
BACKUP_DIR="${BACKUP_DIR:-$HOME/citadel-backups}"
RETENTION=${RETENTION:-7}  # Number of backups to keep

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
ARCHIVE="/tmp/citadel-backup-${TIMESTAMP}.tar.gz"
ENCRYPTED="${BACKUP_DIR}/citadel-backup-${TIMESTAMP}.tar.gz.age"

# === BACKUP ===
echo "Backing up workspace: $WORKSPACE"

# Define expected files and directories
EXPECTED_FILES="SELF.md SOUL.md MEMORY.md AGENTS.md USER.md TOOLS.md IDENTITY.md"
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

echo "Found ${#FOUND_ITEMS[@]} items: ${FOUND_ITEMS[*]}"
if [ ${#MISSING_ITEMS[@]} -gt 0 ]; then
  echo "WARNING: Missing ${#MISSING_ITEMS[@]} items: ${MISSING_ITEMS[*]}"
fi

if [ ${#FOUND_ITEMS[@]} -eq 0 ]; then
  echo "ERROR: Nothing to back up. Check WORKSPACE path."
  exit 1
fi

# Archive only what exists
tar -czf "$ARCHIVE" -C "$WORKSPACE" "${FOUND_ITEMS[@]}"

# Encrypt
echo "Encrypting with age..."
age -r "$AGE_PUBLIC_KEY" -o "$ENCRYPTED" "$ARCHIVE"
rm -f "$ARCHIVE"

SIZE=$(du -h "$ENCRYPTED" | cut -f1)
echo "Backup complete: $ENCRYPTED ($SIZE)"

# === RETENTION ===
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "citadel-backup-*.age" -type f | wc -l | tr -d ' ')
if [ "$BACKUP_COUNT" -gt "$RETENTION" ]; then
  PRUNE_COUNT=$((BACKUP_COUNT - RETENTION))
  echo "Pruning $PRUNE_COUNT old backup(s)..."
  find "$BACKUP_DIR" -name "citadel-backup-*.age" -type f | sort | head -n "$PRUNE_COUNT" | xargs rm -f
fi

echo "Done. $BACKUP_COUNT backup(s) in $BACKUP_DIR (retention: $RETENTION)"
