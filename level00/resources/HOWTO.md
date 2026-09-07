# Level00

The flag that we need to catch is protected in a folder that we can't access :
```bash
$ ls -ld /home/flag00
drwxr-x--- 2 flag00 flag00 4096 Jun  9 19:03 /home/flag00
```

We look for SUID and SGID files, to access elevation :
```bash
$ find / -type f -a \( -perm -u+s -o -perm -g+s \) -exec ls -l {} \; 2> /dev/null
```

That gives us :
```bash
-r-sr-x--- 1 flag00 level00 27112 Jun  9 19:03 /opt/snowcrash/level00/hiro
```
(Note the 's', meaning SUID)

We try to execute it : it's a fake shell. Builtins don't even work.

```bash
strings /opt/snowcrash/level00/hiro
```

One string stands out : '>@f2av5il02puano7naaf6adaf3a'

We try to connect to level1 with : f2av5il02puano7naaf6adaf3a

The password is found !