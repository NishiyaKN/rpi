#!/bin/bash
cd $HOME/rpi/
cp $HOME/.bash_aliases .
cp $HOME/.vimrc .
cp -r $HOME/docker .
git add .
git commit -m 'update files'
git push origin main


