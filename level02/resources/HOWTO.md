# Level01

Just like before, we can't just access the flag file :
```bash
$ ls -ld /home/flag02
drwxr-x--- 2 flag02 flag02 4096 Jun  9 19:03 /home/flag02
```

We also check again for an application in /opt/snowcrash :
```bash
$ ls /opt/snowcrash/level02
kourier
```

We see an app, with no SUID or SGID. When we launch it, it closes right away. When we look at strings :
```bash
$ strings /opt/snowcrash/level02/kourier
# ...
delivery %s for package %s zone %d->%d weight %ug
starting package delivery routing daemon
/tmp/kourier_delivery.tmp
# ...
```
we can guess that the executable is a routing daemon, and there is a log file in `/tmp/kourier_delivery.tmp`.

When we look in the file, we see a password, that must have been sent through the daemon : qi0mauch9ahksha8b6dfe3p0kq

The password is found !