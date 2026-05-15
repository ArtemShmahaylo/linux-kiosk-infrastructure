#!/bin/sh

unclutter -idle 2 -root &

openbox &

sleep 2

while true; do
cd /home/infoscreen/rvplayer/scripts
./start.sh

sleep 5
done