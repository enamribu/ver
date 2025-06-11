#!/bin/bash

# Konfigurasi
WORK_DIR="keyhunt"
PARAM_FILE="param.txt"
SCREEN_PREFIX="keyhunt_"

# Validasi
if [ ! -d "$WORK_DIR" ]; then
    echo "Error: Direktori $WORK_DIR tidak ditemukan!"
    exit 1
fi

if [ ! -f "$WORK_DIR/BTC.py" ]; then
    echo "Error: File BTC.py tidak ditemukan di $WORK_DIR!"
    exit 1
fi

if [ ! -f "$PARAM_FILE" ]; then
    echo "Error: File $PARAM_FILE tidak ditemukan!"
    exit 1
fi

# Bersihkan screen sebelumnya
echo "Membersihkan screen sessions sebelumnya..."
screen -ls | grep "$SCREEN_PREFIX" | awk '{print $1}' | xargs -r -I{} screen -X -S {} quit

# Fungsi untuk menjalankan di screen
run_in_screen() {
    local screen_name=$1
    local param=$2
    
    echo "Memulai screen $screen_name dengan parameter: $param"
    
    # Buat screen dan jalankan BTC.py terlebih dahulu
    screen -dmS "$screen_name" bash -c "
        cd '$WORK_DIR' || exit 1;
        python3 BTC.py;
        exec bash
    "
    
    # Tunggu hingga BTC.py siap menerima input
    sleep 0.5
    
    # Kirim parameter ke screen
    screen -S "$screen_name" -p 0 -X stuff "$param$(printf \\r)"
}

# Proses utama
i=1
while IFS= read -r param || [[ -n "$param" ]]; do
    param=$(echo "$param" | sed 's/#.*//' | xargs)
    [ -z "$param" ] && continue
    
    screen_name="${SCREEN_PREFIX}$i"
    run_in_screen "$screen_name" "$param"
    
    ((i++))
done < "$PARAM_FILE"

# Tampilkan informasi
echo -e "\nScreen yang berjalan:"
screen -ls | grep "$SCREEN_PREFIX"

echo -e "\nPetunjuk:"
echo "1. Akses screen: screen -r <screen_name>"
echo "2. Detach dari screen: Ctrl+A D"
echo "3. List screen: screen -ls"
