# Level01

Just like before, we can't just access the flag file :
```bash
$ ls -ld /home/flag01
drwxr-x--- 2 flag01 flag01 4096 Jun  9 19:03 /home/flag01
```

Like seen in the first level, we know there are programs in `/opt/snowcrash`, so we check them out :
```bash
$ ls -l /opt/snowcrash/level01
total 24
-rwxr-xr-x 1 root root 22656 Jun  9 19:03 gargoyle
```

Launching it creates a floating point exception. We check if there is no instance running :

```bash
$ ps aux | grep gargoyle
flag01       855  0.0  0.0   2684  1224 ?        S    07:09   0:00 /opt/snowcrash/level01/gargoyle kooda7puivaav1idi4f57q8iq0
level01    15947  0.0  0.0   3528  1784 pts/0    S+   10:37   0:00 grep --color=auto gargoyle
```

We see that there is one instance running, launched by user flag01. The argument string seems really suspicious : kooda7puivaav1idi4f57q8iq0

And like that, the password is found !