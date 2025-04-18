#!/bin/bash

# Cek apakah screen sudah terinstal
if ! command -v screen &> /dev/null; then
  echo "screen tidak terinstal. Menginstal sekarang..."
  sudo apt update
  sudo apt install -y screen
  if [ $? -ne 0 ]; then
    echo "Gagal menginstal screen. Mohon periksa errornya."
    exit 1
  fi
else
  echo "screen sudah terinstal."
fi

# Mendapatkan jumlah total core CPU
total_cores=$(nproc --all)

# Menghitung jumlah thread yang akan digunakan (total core - 1)
if [[ "$total_cores" -gt 1 ]]; then
  num_threads=$((total_cores - 1))
else
  # Jika hanya ada 1 core, gunakan 1 thread
  num_threads=1
fi

# Nama sesi screen
session_name="verus"

# Membuat sesi screen baru atau melampirkan jika sudah ada
if screen -list | grep -q "$session_name"; then
  echo "Sesi screen '$session_name' sudah ada. Melampirkan..."
  screen -r "$session_name"
else
  echo "Membuat sesi screen baru '$session_name' dan menjalankan Hellminer..."
  screen -S "$session_name" -d -m bash -c "./hellminer -c stratum+tcp://ap.luckpool.net:3960 -u RLN7r9sRsdu6uwt2vboV2eZ724DzKMv3aP.kdt -p x --threads \"$num_threads\"; exec bash"
  echo "Hellminer berjalan di background dalam sesi screen '$session_name'."
  echo "Untuk melihat sesi, gunakan perintah: screen -r $session_name"
fi

exit 0
