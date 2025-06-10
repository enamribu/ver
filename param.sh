#!/bin/bash

# Fungsi untuk membersihkan screen yang mungkin macet
cleanup_screens() {
    echo "Membersihkan screen sessions yang tersisa..."
    screen -ls | grep -E "keyhunt_[0-9]+" | cut -d. -f1 | awk '{print $1}' | xargs -r kill
}

# Trap untuk menangani sinyal SIGINT (Ctrl+C)
trap cleanup_screens INT

if [ ! -f param.txt ]; then
    echo "File param.txt tidak ditemukan!"
    exit 1
fi

# Pastikan direktori keyhunt ada
if [ ! -d "keyhunt" ]; then
    echo "Direktori keyhunt tidak ditemukan!"
    exit 1
fi

# Pastikan BTC.py ada
if [ ! -f "keyhunt/BTC.py" ]; then
    echo "File keyhunt/BTC.py tidak ditemukan!"
    exit 1
fi

i=1
while IFS= read -r command || [[ -n "$command" ]]; do
    # Trim whitespace dan skip line kosong
    command=$(echo "$command" | xargs)
    [ -z "$command" ] && continue

    screen_name="keyhunt_$i"

    echo "Memulai screen $screen_name dengan command: $command"

    # Buat screen dan jalankan BTC.py dengan timeout untuk memastikan tidak hang
    screen -dmS "$screen_name" bash -c "
        cd keyhunt || exit 1
        echo 'Memulai BTC.py...'
        timeout 10s python3 BTC.py || echo 'Gagal menjalankan BTC.py'
        echo 'BTC.py selesai'
        exec bash
    "

    # Tunggu sampai screen benar-benar ready
    sleep 1

    # Verifikasi screen benar-benar berjalan
    if ! screen -list | grep -q "$screen_name"; then
        echo "Gagal memulai screen $screen_name"
        continue
    fi

    # Kirim perintah ke screen
    screen -S "$screen_name" -p 0 -X stuff "$command$(printf \\r)"
    
    # Tunggu sebentar untuk memastikan command diproses
    sleep 0.5

    i=$((i + 1))
done < param.txt

echo "Semua screen telah dijalankan. Gunakan 'screen -ls' untuk melihat daftar screen."
echo "Gunakan 'screen -r <nama>' untuk mengakses screen tertentu."
