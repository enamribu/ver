#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import random
import argparse

#----------------------------
# ARGUMENTS
#----------------------------
parser = argparse.ArgumentParser(description='Persistent Keyhunt Randomizer in screen')
parser.add_argument('--range', required=True, dest='hex_range',
                    help='Hex range in format <start>:<stop> (no 0x)')
parser.add_argument('--sessions', type=int, default=16,
                    help='Number of parallel sessions')
# Accept interval as two separate args: number and unit
parser.add_argument('--interval', nargs=2, metavar=('NUM', 'UNIT'), default=['10', 'menit'],
                    help='Interval between regenerations, e.g. 10 menit or 1 jam')
parser.add_argument('--screen-name', default='keyhunt_master',
                    help='Name of the master screen session')
args = parser.parse_args()

#----------------------------
# PARSE AND CONFIG
#----------------------------
# Parse range
try:
    min_range_str, max_range_str = args.hex_range.split(':', 1)
except ValueError:
    print("Error: --range harus dalam format <start>:<stop> seperti '1000:1fff'")
    sys.exit(1)
MIN_RANGE = min_range_str
MAX_RANGE = max_range_str
NUM_SESSIONS = args.sessions
MASTER_SCREEN = args.screen_name

# Parse interval values
num, unit = args.interval
if not num.isdigit() or unit.lower() not in ('menit', 'jam'):
    print("Error: --interval harus diikuti oleh jumlah dan satuan 'menit' atau 'jam', contohnya: --interval 1 jam")
    sys.exit(1)
num = int(num)
unit = unit.lower()
# Convert to seconds
if unit == 'menit':
    INTERVAL = num * 60
else:
    INTERVAL = num * 3600
# Human-readable interval string
INTERVAL_STR = f"{num} {unit}"

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
# Determine the -f option dynamically
try:
    f_index = KEYHUNT_PARAMS.index('-f')
    FILE_OPTION = f"-f {KEYHUNT_PARAMS[f_index+1]}"
except (ValueError, IndexError):
    FILE_OPTION = ''

#----------------------------
# AUTO-SPAWN DI SCREEN
#----------------------------
if 'STY' not in os.environ:
    script_path = os.path.abspath(sys.argv[0])
    launch_cmd = (
        f"python3 {script_path} --range {MIN_RANGE}:{MAX_RANGE}"
        f" --sessions {NUM_SESSIONS} --interval {num} {unit}"
        f" --screen-name {MASTER_SCREEN}"
    )
    subprocess.Popen([
        'screen', '-dmS', MASTER_SCREEN,
        'bash', '-lc', launch_cmd
    ])
    print(f"[+] Script dijalankan di screen '{MASTER_SCREEN}'. Menghubungkan...")
    time.sleep(1)
    os.execvp('screen', ['screen', '-r', MASTER_SCREEN])

#----------------------------
# HELPERS
#----------------------------

def hex_to_int(h: str) -> int:
    return int(h, 16)

def int_to_hex(i: int) -> str:
    return format(i, 'x')

#----------------------------
# SESSION MANAGEMENT
#----------------------------

def kill_old_sessions():
    for i in range(NUM_SESSIONS):
        name = f"keyhunt_{i}"
        subprocess.run(
            ["screen", "-S", name, "-X", "quit"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )


def launch_sessions():
    lo = hex_to_int(MIN_RANGE)
    hi = hex_to_int(MAX_RANGE)
    # Generate unique breakpoints to partition contiguously
    pts = set()
    while len(pts) < NUM_SESSIONS - 1:
        pts.add(random.randint(lo, hi))
    sorted_pts = sorted(pts)
    breakpoints = [lo] + sorted_pts + [hi]

    for i in range(NUM_SESSIONS):
        start_int = breakpoints[i]
        stop_int = breakpoints[i + 1]
        start = int_to_hex(start_int)
        stop = int_to_hex(stop_int)
        session = f"keyhunt_{i}"
        cmd = [
            "screen", "-dmS", session,
            "bash", "-c",
            f"cd keyhunt && ./keyhunt -r {start}:{stop} {' '.join(KEYHUNT_PARAMS)}"
        ]
        subprocess.Popen(cmd)
        # Dynamically include the -f option in log
        print(f"[+] Started {session}: -r {start}:{stop} {FILE_OPTION}")

#----------------------------
# MAIN LOOP
#----------------------------

def main():
    print(f"=== Keyhunt Randomizer Started di screen '{MASTER_SCREEN}' ===")
    while True:
        kill_old_sessions()
        launch_sessions()
        print(f"-- Menunggu {INTERVAL_STR} sebelum regenerasi range --\n")
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()
