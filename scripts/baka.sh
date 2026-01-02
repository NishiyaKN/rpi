#!/bin/bash

# Set explicit paths (Cron doesn't always know where 'git' is)
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Define Variables
SOURCE_DIR="/home/zero/docker"
BACKUP_DIR="/home/zero/rpi"
LOG_FILE="/home/zero/backup_log.txt"

# Start Log
echo "--- Backup started: $(date) ---" >> "$LOG_FILE"

# Copy Dotfiles
cp /home/zero/.bash_aliases "$BACKUP_DIR/config"
cp /home/zero/.vimrc "$BACKUP_DIR/config"

# Rsync (Fixed Security & Paths)
# Note the trailing slash on SOURCE_DIR/ to copy CONTENTS, not the folder itself
rsync -av --delete \
    --exclude '.env' \
    --exclude '.git' \
    --exclude '*.db' \
    --exclude '*.db-journal' \
    --exclude '*.db-shm' \
    --exclude '*.db-wal' \
    --exclude 'logrotate' \
    --exclude 'cli_pw' \
    --exclude 'wg0.conf' \
    --exclude 'wg0.json' \
    --exclude '*ed25519' \
    "$SOURCE_DIR/" "$BACKUP_DIR/docker/" >> "$LOG_FILE" 2>&1

# Git Push (Only if changes exist)
cd "$BACKUP_DIR" || exit

git add -A

if ! git diff --cached --quiet; then
    echo "Changes detected (including potential updates to pi.sh or folders)" >> "$LOG_FILE"
    
    git commit -m "Backup: $(date +'%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE" 2>&1
    git push origin main >> "$LOG_FILE" 2>&1
    
    echo "Success: Changes pushed." >> "$LOG_FILE"
else
    echo "Info: No changes detected in any files." >> "$LOG_FILE"
fi

echo "---------------------------------" >> "$LOG_FILE"
