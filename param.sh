#!/bin/bash

if [ ! -f param.txt ]; then
    echo "File param.txt tidak ditemukan!"
    exit 1
fi

i=1
while IFS= read -r command
do
    command=$(echo "$command" | xargs)

    screen_name="keyhunt_$i"

    # Buat screen dan jalankan BTC.py
    screen -dmS "$screen_name" bash -c "
        cd keyhunt || exit 1
        python3 BTC.py
        exec bash
    "

    # Tunggu sebentar agar BTC.py sempat loading
    sleep 2

    # Kirim perintah dari param.txt ke dalam screen
    screen -S "$screen_name" -p 0 -X stuff "$command$(printf \\r)"

    echo "Screen $screen_name dijalankan: $command"
    i=$((i + 1))
done < param.txt
