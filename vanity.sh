#!/bin/bash

# Pastikan skrip dijalankan dengan hak akses root (sudo)
if [ "$(id -u)" -ne 0 ]; then
  echo "Skrip ini perlu dijalankan dengan hak akses root (sudo)."
  exit 1
fi

echo "Memulai proses instalasi dan konfigurasi..."

# 1. Update dan upgrade paket sistem
echo "LANGKAH 1: Melakukan update dan upgrade paket sistem..."
apt update && apt upgrade -y
if [ $? -ne 0 ]; then
    echo "Gagal melakukan update dan upgrade paket sistem. Menghentikan skrip."
    exit 1
fi
echo "Update dan upgrade paket sistem selesai."
echo ""

# Instalasi paket yang dibutuhkan
echo "LANGKAH 2: Menginstall paket yang dibutuhkan (git, build-essential, libssl-dev, libgmp-dev)..."
apt install git -y
if [ $? -ne 0 ]; then
    echo "Gagal menginstall git. Menghentikan skrip."
    exit 1
fi

apt install build-essential -y
if [ $? -ne 0 ]; then
    echo "Gagal menginstall build-essential. Menghentikan skrip."
    exit 1
fi

apt install libssl-dev -y
if [ $? -ne 0 ]; then
    echo "Gagal menginstall libssl-dev. Menghentikan skrip."
    exit 1
fi

apt install libgmp-dev -y
if [ $? -ne 0 ]; then
    echo "Gagal menginstall libgmp-dev. Menghentikan skrip."
    exit 1
fi
echo "Instalasi paket yang dibutuhkan selesai."
echo ""

# 2. Clone repository keyhunt
echo "LANGKAH 3: Melakukan clone repository keyhunt..."
# Hapus direktori keyhunt jika sudah ada untuk menghindari konflik
if [ -d "keyhunt" ]; then
    echo "Direktori 'keyhunt' sudah ada. Menghapus direktori lama..."
    rm -rf keyhunt
fi
git clone https://github.com/enamribu/keyhunt.git
if [ $? -ne 0 ]; then
    echo "Gagal melakukan clone repository keyhunt. Menghentikan skrip."
    exit 1
fi
echo "Clone repository keyhunt selesai."
echo ""

# 3. Masuk ke direktori keyhunt
echo "LANGKAH 4: Masuk ke direktori keyhunt..."
cd keyhunt
if [ $? -ne 0 ]; then
    echo "Gagal masuk ke direktori keyhunt. Pastikan repository berhasil di-clone. Menghentikan skrip."
    exit 1
fi
echo "Berhasil masuk ke direktori keyhunt."
echo ""

# 4. Compile keyhunt
echo "LANGKAH 5: Melakukan kompilasi keyhunt menggunakan 'make'..."
make
if [ $? -ne 0 ]; then
    echo "Gagal melakukan kompilasi keyhunt. Pastikan semua dependensi terinstall dengan benar. Menghentikan skrip."
    exit 1
fi
echo "Kompilasi keyhunt selesai."
echo ""

# Kembali ke direktori sebelumnya (opsional, tergantung di mana Anda ingin BTC.py diunduh)
# cd ..

# 5. Download BTC.py
echo "LANGKAH 6: Mengunduh BTC.py..."
# Mengunduh ke direktori saat ini (yaitu di dalam keyhunt)
# Jika ingin di direktori lain, sesuaikan path atau cd .. terlebih dahulu
wget https://raw.githubusercontent.com/enamribu/ver/refs/heads/main/BTC.py -O BTC.py
if [ $? -ne 0 ]; then
    echo "Gagal mengunduh BTC.py. Menghentikan skrip."
    exit 1
fi
# Memberikan izin eksekusi pada BTC.py
chmod +x BTC.py
echo "Pengunduhan BTC.py selesai dan izin eksekusi telah diberikan."
echo ""

# 6. Membuat screen dengan nama btc dan menjalankan BTC.py
echo "LANGKAH 7: Membuat sesi screen 'btc' dan menjalankan BTC.py..."
# Cek apakah screen sudah terinstall
if ! command -v screen &> /dev/null
then
    echo "'screen' tidak terinstall. Mencoba menginstall..."
    apt install screen -y
    if [ $? -ne 0 ]; then
        echo "Gagal menginstall 'screen'. Anda perlu menginstallnya secara manual. Menghentikan skrip."
        exit 1
    fi
    echo "'screen' berhasil diinstall."
fi

# Membuat dan menjalankan skrip dalam sesi screen baru
# -S btc: nama sesi
# -dm: detach mode (memulai screen di background)
# python3 ./BTC.py: perintah yang dijalankan di dalam screen
# Pastikan python3 terinstall atau ganti dengan 'python' jika menggunakan versi python yang berbeda
screen -S btc -dm python3 ./BTC.py
if [ $? -ne 0 ]; then
    echo "Gagal membuat sesi screen 'btc' atau menjalankan BTC.py. Periksa log screen."
    # Untuk melihat log screen, Anda bisa attach ke sesi: screen -r btc
    exit 1
fi

echo ""
echo "Semua proses telah selesai."
echo "Skrip BTC.py sekarang berjalan di dalam sesi screen bernama 'btc'."
echo "Anda dapat menghubungkan kembali ke sesi screen dengan perintah: screen -r btc"
echo "Untuk keluar dari sesi screen tanpa menghentikan skrip, tekan Ctrl+A lalu D."

exit 0
