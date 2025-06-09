#!/bin/bash

mapfile -t cmds < keyhunt_commands.txt

for i in "${!cmds[@]}"; do
    idx=$((i+1))
    screen -dmS screen$idx bash -c "
        cd keyhunt
        echo | script -q -c 'python3 BTC.py' /dev/null &
        stdbuf -oL -eL ${cmds[i]}
    "
done
