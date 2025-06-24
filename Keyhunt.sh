#!/bin/bash

echo "Memulai proses instalasi dan konfigurasi Keyhunt..."
echo "----------------------------------------------------"

# 1. Update package list dan upgrade sistem
echo "Langkah 1: Melakukan apt update..."
sudo apt update
if [ $? -ne 0 ]; then
    echo "Error: Gagal melakukan apt update. Mohon periksa koneksi internet dan coba lagi."
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
echo "----------------------------------------------------"
echo "Kompilasi berhasil."
echo "----------------------------------------------------"

exit 0
