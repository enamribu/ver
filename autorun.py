#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import random
import argparse
import threading
import requests
import shlex

#----------------------------
# CONFIGURATION
#----------------------------
TELEGRAM_TOKEN = "7513012504:AAFYmIgQgLzp0k_J63E22LtM-A6Xq9UvXEU"
TELEGRAM_CHAT_ID = "513265991"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
KEYFOUND_FILE = os.path.join(SCRIPT_DIR, 'keyhunt', 'KEYFOUNDKEYFOUND.txt')

#----------------------------
# ARGUMENTS
#----------------------------
parser = argparse.ArgumentParser(
    description='Persistent Keyhunt Randomizer in screen with Telegram alert',
    epilog='Contoh penggunaan:\n'
           './autorun.py --range 1ce35f60c4c83be2765:1ffffffffffffffffff '
           '--sessions 16 '
           '--params "-l compress -m address -c btc -f tests/73.txt -t 1 -R -s 10 -q -n 0x1000"',
    formatter_class=argparse.RawTextHelpFormatter
)

parser.add_argument(
    '--range', required=True, dest='hex_range',
    help='Hex range dalam format <start>:<stop> (tanpa 0x) [WAJIB]'
)
parser.add_argument(
    '--sessions', type=int, required=True,
    help='Jumlah sesi parallel [WAJIB]'
)
parser.add_argument(
    '--min-interval', type=int, default=15,
    help='Minimum interval dalam menit (default: 15 menit)'
)
parser.add_argument(
    '--max-interval', type=int, default=75,
    help='Maximum interval dalam menit (default: 75 menit)'
)
parser.add_argument(
    '--params', required=True,
    help='Parameter keyhunt sebagai string (gunakan quotes) [WAJIB]'
)
parser.add_argument(
    '--screen-name', required=False, default='keyhunt_master',
    help='Nama master screen session (opsional)'
)

args = parser.parse_args()

#----------------------------
# VALIDASI PARAMETER
#----------------------------
try:
    MIN_RANGE, MAX_RANGE = args.hex_range.split(':', 1)
    int(MIN_RANGE, 16)
    int(MAX_RANGE, 16)
except ValueError as e:
    print(f"Error: Range tidak valid - {e}")
    sys.exit(1)

NUM_SESSIONS = args.sessions
if NUM_SESSIONS < 1:
    print("Error: Jumlah sessions minimal 1")
    sys.exit(1)

if args.min_interval < 1 or args.max_interval < args.min_interval:
    print("Error: Interval minimum harus lebih kecil dari maximum dan minimal 1 menit")
    sys.exit(1)

try:
    KEYHUNT_PARAMS = shlex.split(args.params)
    if '-m' not in KEYHUNT_PARAMS:
        print("Error: Parameter keyhunt harus mencakup minimal -m")
        sys.exit(1)
except Exception as e:
    print(f"Error parsing --params: {e}")
    sys.exit(1)

FILE_OPTION = 'N/A'  # Default value
try:
    file_idx = KEYHUNT_PARAMS.index('-f')
    FILE_OPTION = KEYHUNT_PARAMS[file_idx+1]
except ValueError:
    pass  # Tidak menggunakan parameter -f

MASTER_SCREEN = args.screen_name

#----------------------------
# FUNGSI UTILITAS
#----------------------------
def send_telegram(message: str):
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    payload = {
        'chat_id': TELEGRAM_CHAT_ID,
        'text': message
    }
    try:
        resp = requests.post(url, json=payload, timeout=10)
        resp.raise_for_status()
    except Exception as e:
        print(f"[!] Gagal kirim Telegram: {e}")

def get_new_keys(filepath: str, last_pos: int):
    new_blocks = []
    if not os.path.exists(filepath):
        return new_blocks, last_pos
    size = os.path.getsize(filepath)
    if size <= last_pos:
        return new_blocks, last_pos
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        f.seek(last_pos)
        data = f.read()
        last_pos = f.tell()
    parts = [b.strip() for b in data.split('\n\n') if b.strip()]
    for part in parts:
        lines = [l.strip() for l in part.split('\n') if l.strip()]
        if lines:
            new_blocks.append(lines)
    return new_blocks, last_pos

def format_key_block(lines):
    header = 'KEY FOUND!'
    return header + '\n' + '\n'.join(lines)

def generate_random_interval(min_minutes, max_minutes):
    """Generate random interval in seconds between min and max minutes"""
    minutes = random.randint(min_minutes, max_minutes)
    hours = minutes // 60
    remaining_minutes = minutes % 60
    
    if hours > 0 and remaining_minutes > 0:
        interval_str = f"{hours} J {remaining_minutes} M"
    elif hours > 0:
        interval_str = f"{hours} J"
    else:
        interval_str = f"{minutes} M"
    
    return minutes * 60, interval_str

def monitor_keyfound_thread():
    last_pos = os.path.getsize(KEYFOUND_FILE) if os.path.exists(KEYFOUND_FILE) else 0
    while True:
        blocks, last_pos = get_new_keys(KEYFOUND_FILE, last_pos)
        for blk in blocks:
            msg = format_key_block(blk)
            print(f"[+] {msg}")
            send_telegram(msg)
        time.sleep(1)

monitor_thread = threading.Thread(target=monitor_keyfound_thread, daemon=True)
monitor_thread.start()

#----------------------------
# SCREEN SPAWN
#----------------------------
if 'STY' not in os.environ:
    script = os.path.abspath(sys.argv[0])
    cmd = (
        f"python3 {script} --range {MIN_RANGE}:{MAX_RANGE}"
        f" --sessions {NUM_SESSIONS}"
        f" --min-interval {args.min_interval}"
        f" --max-interval {args.max_interval}"
        f" --params '{args.params}'"
        f" --screen-name {MASTER_SCREEN}"
    )
    subprocess.Popen(['screen', '-dmS', MASTER_SCREEN, 'bash', '-lc', cmd])
    print(f"[+] Launched in screen '{MASTER_SCREEN}' and attaching...")
    time.sleep(1)
    os.execvp('screen', ['screen', '-r', MASTER_SCREEN])

#----------------------------
# MANAJEMEN SESSION
#----------------------------
def hex_to_int(h: str) -> int:
    return int(h, 16)

def int_to_hex(i: int) -> str:
    return format(i, 'x')

def kill_old_sessions():
    for i in range(NUM_SESSIONS):
        subprocess.run(['screen', '-S', f'keyhunt_{i}', '-X', 'quit'],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def launch_sessions():
    lo, hi = hex_to_int(MIN_RANGE), hex_to_int(MAX_RANGE)
    pts = set()
    while len(pts) < NUM_SESSIONS - 1:
        pts.add(random.randint(lo, hi))
    breakpoints = [lo] + sorted(pts) + [hi]
    for i in range(NUM_SESSIONS):
        s_hex = int_to_hex(breakpoints[i])
        e_hex = int_to_hex(breakpoints[i+1])
        print(f"[+] Started keyhunt_{i}: -r {s_hex}:{e_hex} -f {FILE_OPTION}")
        subcmd = f"cd keyhunt && ./keyhunt -r {s_hex}:{e_hex} {' '.join(KEYHUNT_PARAMS)}"
        subprocess.Popen(['screen', '-dmS', f'keyhunt_{i}', 'bash', '-lc', subcmd])

#----------------------------
# MAIN LOOP
#----------------------------
def main():
    print("\n=== KONFIGURASI AKTIF ===")
    print(f"Master Screen  : {MASTER_SCREEN}")
    print(f"Hex Range      : {MIN_RANGE}:{MAX_RANGE}")
    print(f"Jumlah Session : {NUM_SESSIONS}")
    print(f"Interval Range : {args.min_interval} - {args.max_interval} menit")
    print(f"File Target    : {FILE_OPTION}")
    print("="*30 + "\n")

    while True:
        kill_old_sessions()
        launch_sessions()
        
        # Generate random interval each cycle
        interval_seconds, interval_str = generate_random_interval(
            args.min_interval, args.max_interval
        )
        print(f"\n {interval_str} {' '.join(KEYHUNT_PARAMS)}")
        time.sleep(interval_seconds)

if __name__ == '__main__':
    main()
