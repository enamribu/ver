#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import random
import argparse
import threading
import requests

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
    description='Persistent Keyhunt Randomizer in screen with Telegram alert'
)
parser.add_argument(
    '--range', required=True, dest='hex_range',
    help='Hex range in format <start>:<stop> (no 0x)'
)
parser.add_argument(
    '--sessions', type=int, default=16,
    help='Number of parallel sessions'
)
parser.add_argument(
    '--interval', nargs=2, metavar=('NUM', 'UNIT'), default=['10', 'menit'],
    help='Interval between regenerations, e.g. 10 menit or 1 jam'
)
parser.add_argument(
    '--screen-name', default='keyhunt_master',
    help='Name of the master screen session'
)
args = parser.parse_args()

#----------------------------
# PARSE AND SETUP
#----------------------------
try:
    MIN_RANGE, MAX_RANGE = args.hex_range.split(':', 1)
except ValueError:
    print("Error: --range harus dalam format <start>:<stop>")
    sys.exit(1)
NUM_SESSIONS = args.sessions
MASTER_SCREEN = args.screen_name
num_str, unit_str = args.interval
if not num_str.isdigit() or unit_str.lower() not in ('menit', 'jam'):
    print("Error: --interval harus 'X menit' atau 'X jam'")
    sys.exit(1)
num = int(num_str)
unit = unit_str.lower()
INTERVAL = num * (60 if unit == 'menit' else 3600)
INTERVAL_STR = f"{num} {unit}"

#----------------------------
# KEYHUNT PARAMETERS
#----------------------------
KEYHUNT_PARAMS = [
    "-l", "compress",
    "-m", "address",
    "-c", "btc",
    "-f", "tests/71.txt",
    "-t", "1",
    "-R",
    "-s", "5",
    "-q",
    "-n", "0x1000",
]
try:
    idx = KEYHUNT_PARAMS.index('-f')
    FILE_OPTION = f"-f {KEYHUNT_PARAMS[idx+1]}"
except ValueError:
    FILE_OPTION = ''

#----------------------------
# TELEGRAM FUNCTION
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

#----------------------------
# NEW KEY DETECTION
#----------------------------
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

#----------------------------
# FORMAT KEY BLOCK
#----------------------------
def format_key_block(lines):
    header = 'KEY FOUND!'
    return header + '\n' + '\n'.join(lines)

#----------------------------
# MONITOR THREAD
#----------------------------

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
# SCREEN SPAWN IF NEEDED
#----------------------------
if 'STY' not in os.environ:
    script = os.path.abspath(sys.argv[0])
    cmd = (
        f"python3 {script} --range {MIN_RANGE}:{MAX_RANGE}"
        f" --sessions {NUM_SESSIONS} --interval {num} {unit}"
        f" --screen-name {MASTER_SCREEN}"
    )
    subprocess.Popen(['screen', '-dmS', MASTER_SCREEN, 'bash', '-lc', cmd])
    print(f"[+] Launched in screen '{MASTER_SCREEN}' and attaching...")
    time.sleep(1)
    os.execvp('screen', ['screen', '-r', MASTER_SCREEN])

#----------------------------
# HELPERS & SESSION MGMT
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
        subcmd = f"cd keyhunt && ./keyhunt -r {s_hex}:{e_hex} {' '.join(KEYHUNT_PARAMS)}"
        subprocess.Popen(['screen', '-dmS', f'keyhunt_{i}', 'bash', '-lc', subcmd])
        print(f"[+] Started keyhunt_{i}: -r {s_hex}:{e_hex} {FILE_OPTION}")

#----------------------------
# MAIN LOOP
#----------------------------

def main():
    print(f"=== Keyhunt Randomizer Started in '{MASTER_SCREEN}' ===")
    while True:
        kill_old_sessions()
        launch_sessions()
        print(f"-- Menunggu {INTERVAL_STR} sebelum regenerasi range --\n")
        time.sleep(INTERVAL)

if __name__ == '__main__':
    main()
