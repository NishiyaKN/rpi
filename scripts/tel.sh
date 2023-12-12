#!/bin/bash
CURRENT_DIR=$(pwd)
cd $HOME/rpi/teleporter
pihole -a -t
cd $CURRENT_DIR

