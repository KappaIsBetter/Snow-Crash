# Level00

## Enumeration

Find SUID and SGID files :
```bash
find / -type f -a \( -perm -u+s -o -perm -g+s \) -exec ls -l {} \; 2> /dev/null
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