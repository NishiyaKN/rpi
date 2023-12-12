#!/bin/bash
cd $HOME/rpi/
git pull
cp $HOME/.bash_aliases .
git add .
git commit -m 'update files'
git push origin main


