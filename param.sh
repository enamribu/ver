#!/bin/bash

mapfile -t cmds < param.txt

for i in "${!cmds[@]}"; do
    idx=$((i+1))
    screen -dmS screen$idx bash -c "
        cd keyhunt
        echo | script -q -c 'python3 BTC.py' /dev/null > btcpy-log$idx.txt 2>&1 &
        stdbuf -oL -eL ${cmds[i]} | tee keyhunt-log$idx.txt
    "
done
