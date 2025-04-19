#!/bin/bash

# Langkah 1: Install screen jika belum terpasang
if ! command -v screen &> /dev/null; then
  echo "Menginstall screen..."
  sudo apt update
  sudo apt install -y screen
else
  echo "screen sudah terpasang."
fi

# Langkah 2: Membuka sesi screen baru
echo "Membuka sesi screen baru dengan nama 'cuwan'..."
screen -S cuwan -dm

# Mendapatkan nama sesi screen
session_name="cuwan"

# Langkah 3: Mendownload Hellminer dari GitHub di dalam sesi screen
github_url="https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_linux64.tar.gz"
download_command="wget $github_url -O hellminer.tar.gz"
screen -S "$session_name" -X stuff "$download_command^M"
echo "Memulai download Hellminer di dalam sesi screen..."
sleep 5 # Beri waktu sebentar untuk download dimulai

# Langkah 4: Mengekstrak Hellminer di dalam sesi screen
extract_command="tar -xvf hellminer.tar.gz"
screen -S "$session_name" -X stuff "$extract_command^M"
echo "Memulai ekstraksi Hellminer di dalam sesi screen..."
sleep 5 # Beri waktu sebentar untuk ekstraksi selesai

# Langkah 5: Menjalankan Hellminer dengan menyisakan 1 CPU di dalam sesi screen
# Mendapatkan jumlah total core CPU
total_cores=$(nproc --all)

# Menghitung jumlah thread yang akan digunakan (total core - 1)
if [[ "$total_cores" -gt 1 ]]; then
  num_threads=$((total_cores - 1))
else
  num_threads=1
fi

run_command="./hellminer -c stratum+tcp://eu.luckpool.net:3960 -u RLN7r9sRsdu6uwt2vboV2eZ724DzKMv3aP.jiwa1 -p x --threads \"$num_threads\""
screen -S "$session_name" -X stuff "$run_command^M"
echo "Menjalankan Hellminer di dalam sesi screen dengan $num_threads thread (total core: $total_cores)."

echo "Sesi screen 'cuwan' telah dibuat dan Hellminer sedang berjalan di dalamnya."
echo "Anda dapat melihat sesi dengan perintah: screen -r $session_name"
