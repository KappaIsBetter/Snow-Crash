#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/cred.h>
#include <linux/sched.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/err.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("flagbonus05");
MODULE_DESCRIPTION("Rife fiber control interface");
MODULE_VERSION("1.0");

static char rife_data[4096];
static struct proc_dir_entry *rife_entry;

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

static int rife_proc_show(struct seq_file *m, void *v)
{
    seq_puts(m, rife_data);
    return 0;
}

static int __init rife_init(void)
{
    int ret;

    ret = rife_read_flag();
    if (ret) {
        pr_err("rife: failed to read\n");
        return ret;
    }

    rife_entry = proc_create_single("rife", 0444, NULL, rife_proc_show);
    if (!rife_entry) {
        pr_err("rife: failed to create /proc/rife\n");
        return -ENOMEM;
    }

    pr_info("rife: flag data cached and proc entry created\n");
    return 0;
}

static void __exit rife_exit(void)
{
    if (rife_entry)
        proc_remove(rife_entry);
    pr_info("rife: unloaded\n");
}

module_init(rife_init);
module_exit(rife_exit);
