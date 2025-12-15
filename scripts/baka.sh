#!/bin/bash
cp $HOME/.bash_aliases $HOME/rpi
cp $HOME/.vimrc . $HOME/rpi

rsync -av --delete \
    --exclude '.env' \
    --exclude '*.db' \
    --exclude '*.db-journal' \
    --exclude '.git' \
    "$HOME/docker" "$HOME/rpi"

git add .
git commit -m "Backup: $(date +'%Y-%m-%d %H:%M:%S')"
git push origin main
