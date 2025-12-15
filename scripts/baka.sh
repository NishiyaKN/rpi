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
cp /home/zero/.bash_aliases "$BACKUP_DIR/"
cp /home/zero/.vimrc "$BACKUP_DIR/"

# Rsync (Fixed Security & Paths)
# Note the trailing slash on SOURCE_DIR/ to copy CONTENTS, not the folder itself
rsync -av --delete \
    --exclude '.env' \
    --exclude '*.db' \
    --exclude '*.db-journal' \
    --exclude '.git' \
    --exclude 'wg0.conf' \
    --exclude 'wg0.json' \
    "$SOURCE_DIR/" "$BACKUP_DIR/docker/" >> "$LOG_FILE" 2>&1

# Git Push (Only if changes exist)
cd "$BACKUP_DIR" || exit

# Check if there are changes before committing
if [[ -n $(git status -s) ]]; then
    git add .
    git commit -m "Backup: $(date +'%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE" 2>&1

    git push origin main >> "$LOG_FILE" 2>&1
    
    echo "Success: Changes pushed." >> "$LOG_FILE"
else
    echo "Info: No changes to backup." >> "$LOG_FILE"
fi

echo "---------------------------------" >> "$LOG_FILE"
