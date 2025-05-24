#!/bin/bash

# Skrip untuk menginstal dependensi, mengkloning, mengkompilasi, dan menjalankan keyhunt dalam screen

# Pesan Awal
echo "Memulai proses instalasi dan konfigurasi Keyhunt..."
echo "----------------------------------------------------"

# 1. Update package list dan upgrade sistem
echo "Langkah 1: Melakukan apt update dan apt upgrade..."
sudo apt update && sudo apt upgrade -y
if [ $? -ne 0 ]; then
    echo "Error: Gagal melakukan apt update atau apt upgrade. Mohon periksa koneksi internet dan coba lagi."
    exit 1
fi
echo "----------------------------------------------------"

# 2. Install dependensi yang dibutuhkan
echo "Langkah 2: Menginstal dependensi (git, build-essential, libssl-dev, libgmp-dev)..."
sudo apt install git -y
if [ $? -ne 0 ]; then
    echo "Error: Gagal menginstal git."
    exit 1
fi

sudo apt install build-essential -y
if [ $? -ne 0 ]; then
    echo "Error: Gagal menginstal build-essential."
    exit 1
fi

sudo apt install libssl-dev -y
if [ $? -ne 0 ]; then
    echo "Error: Gagal menginstal libssl-dev."
    exit 1
fi

sudo apt install libgmp-dev -y
if [ $? -ne 0 ]; then
    echo "Error: Gagal menginstal libgmp-dev."
    exit 1
fi
echo "Dependensi berhasil diinstal."
echo "----------------------------------------------------"

# 3. Clone repository keyhunt
echo "Langkah 3: Mengkloning repository keyhunt dari GitHub..."
# Hapus direktori keyhunt jika sudah ada untuk menghindari konflik
if [ -d "keyhunt" ]; then
    echo "Direktori 'keyhunt' sudah ada. Menghapusnya..."
    rm -rf keyhunt
fi
git clone https://github.com/enamribu/keyhunt.git
if [ $? -ne 0 ]; then
    echo "Error: Gagal mengkloning repository keyhunt. Periksa URL repository atau koneksi internet."
    exit 1
fi
echo "Repository berhasil dikloning."
echo "----------------------------------------------------"

# 4. Masuk ke direktori keyhunt
echo "Langkah 4: Masuk ke direktori 'keyhunt'..."
cd keyhunt
if [ $? -ne 0 ]; then
    echo "Error: Gagal masuk ke direktori 'keyhunt'. Pastikan repository berhasil dikloning."
    exit 1
fi
echo "Berada di direktori $(pwd)"
echo "----------------------------------------------------"

# 5. Compile keyhunt
echo "Langkah 5: Mengkompilasi keyhunt menggunakan 'make'..."
make
if [ $? -ne 0 ]; then
    echo "Error: Gagal mengkompilasi keyhunt. Pastikan semua dependensi build terinstal dengan benar."
    exit 1
fi
echo "Kompilasi berhasil."
echo "----------------------------------------------------"

# 6. Membuat screen dengan nama btc dan membukanya
# 7. Menjalankan BTC.py didalam screen
echo "Langkah 6 & 7: Membuat screen 'btc' dan menjalankan 'BTC.py' di dalamnya..."

# Periksa apakah BTC.py ada
if [ ! -f "BTC.py" ]; then
    echo "Error: File 'BTC.py' tidak ditemukan di direktori 'keyhunt'. Pastikan file tersebut ada."
    # Mencoba mencari file python lain jika BTC.py tidak ada, sebagai alternatif
    # Misalnya, jika ada keyhunt.py atau file python utama lainnya.
    # Untuk contoh ini, kita akan tetap keluar jika BTC.py tidak ada.
    exit 1
fi

# Periksa apakah screen sudah terinstal
if ! command -v screen &> /dev/null
then
    echo "'screen' tidak terinstal. Mencoba menginstal..."
    sudo apt install screen -y
    if [ $? -ne 0 ]; then
        echo "Error: Gagal menginstal 'screen'. Mohon instal secara manual dan jalankan skrip lagi."
        exit 1
    fi
fi

# Membuat dan menjalankan perintah di dalam screen
# Opsi -S btc: Membuat sesi screen dengan nama 'btc'
# Opsi -d -m: Memulai screen dalam mode detached (background)
# sh -c 'python3 BTC.py; exec bash': Menjalankan BTC.py, dan setelah selesai, menjaga sesi screen tetap terbuka dengan bash
# Anda mungkin perlu menyesuaikan 'python3' menjadi 'python' tergantung konfigurasi server Anda
screen -S btc -d -m sh -c 'python3 BTC.py; exec bash'

if [ $? -ne 0 ]; then
    echo "Error: Gagal membuat atau menjalankan perintah di dalam screen 'btc'."
    echo "Anda bisa mencoba menjalankan secara manual: screen -S btc lalu python3 BTC.py"
    exit 1
fi

echo "----------------------------------------------------"
echo "Proses selesai!"
echo "Keyhunt seharusnya sekarang berjalan di dalam sesi screen bernama 'btc'."
echo "Untuk masuk ke screen, gunakan perintah: screen -r btc"
echo "Untuk keluar dari screen tanpa menghentikan proses (detach), tekan Ctrl+A lalu D."
echo "----------------------------------------------------"

exit 0
