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
# New argument: pass through keyhunt parameters directly
parser.add_argument(
    '--keyhunt-params', nargs='+',
    default=[
        '-l', 'compress',
        '-m', 'address',
        '-c', 'btc',
        '-f', 'tests/73.txt',
        '-t', '1',
        '-R',
        '-s', '5',
        '-q',
        '-n', '0x1000'
    ],
    help='Parameters to pass directly to keyhunt executable'
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
# KEYHUNT PARAMETERS (override via CLI)
#----------------------------
KEYHUNT_PARAMS = args.keyhunt_params

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
# KEYHUNT OUTPUT PARSER
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
# SESSION LAUNCHER
#----------------------------
def launch_sessions():
    """
    Launch KEYHUNT sessions in detached screen windows.
    Each session uses range from MIN_RANGE to MAX_RANGE and shared KEYHUNT_PARAMS.
    """
    lo = int(MIN_RANGE, 16)
    hi = int(MAX_RANGE, 16)
    step = (hi - lo) // NUM_SESSIONS
    for i in range(NUM_SESSIONS):
        start = lo + i * step
        end = start + step - 1 if i < NUM_SESSIONS - 1 else hi
        s_hex = hex(start)
        e_hex = hex(end)
        subcmd = (
            f"cd keyhunt && ./keyhunt -r {s_hex}:{e_hex} "
            f"{' '.join(KEYHUNT_PARAMS)}"
        )
        session_name = f"keyhunt_{i}"
        subprocess.Popen(
            ['screen', '-dmS', session_name, 'bash', '-lc', subcmd]
        )
        print(f"[+] Started {session_name}: -r {s_hex}:{e_hex} {' '.join(KEYHUNT_PARAMS)}")

#----------------------------
# MONITOR THREAD
#----------------------------
def monitor_keyfound():
    last_pos = 0
    while True:
        new_blocks, last_pos = get_new_keys(KEYFOUND_FILE, last_pos)
        for block in new_blocks:
            message = '\n'.join(block)
            send_telegram(f"[KEY FOUND]\n{message}")
        time.sleep(5)

#----------------------------
# MAIN LOOP
#----------------------------
def main():
    # Spawn monitor thread
    monitor_thread = threading.Thread(target=monitor_keyfound, daemon=True)
    monitor_thread.start()

    # Initial launch
    launch_sessions()
    print(f"-- Semua {NUM_SESSIONS} sesi berjalan di screen '{MASTER_SCREEN}'")

    # Periodic regeneration
    while True:
        print(f"-- Menunggu {INTERVAL_STR} sebelum regenerasi range --\n")
        time.sleep(INTERVAL)
        # Reload sessions
        subprocess.call(['screen', '-S', MASTER_SCREEN, '-X', 'quit'])
        launch_sessions()

if __name__ == '__main__':
    main()
