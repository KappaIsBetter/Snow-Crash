import subprocess, time

p = "/dev/shm/ng_channel"

for size in range(0,100):
    with open(p, "r+b", buffering=0) as f:
        f.truncate(size)

    try:
        pid = subprocess.check_output(
            ["pgrep", "-u", "flagbonus01", "-x", "ng"],
            text=True
        ).strip()
    except subprocess.CalledProcessError:
        pid = "ABSENT"

    print(f"{size:2d} -> {pid}")