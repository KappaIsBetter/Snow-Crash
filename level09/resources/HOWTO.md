# Level 09

We got one binary file in /opt/snowcrash/level09 : 

```bash
level09@snowcrash:~$ ls -la /opt/snowcrash/level09
total 28
drwxr-xr-x  2 root   root   4096 Jun  9 19:04 .
drwxr-xr-x 18 root   root   4096 Jun  9 19:04 ..
-r-sr-x---  1 flag09 da5id 16896 Jun  9 19:03 da5id
```

Lets try some test since we can exec it:

```bash
level09@snowcrash:/opt/snowcrash/level09$ ./da5id 
Usage: ./da5id <token>
level09@snowcrash:/opt/snowcrash/level09$ ./da5id 123
Token does not meet policy requirements.
level09@snowcrash:/opt/snowcrash/level09$ ./da5id dwa
Token does not meet policy requirements.
level09@snowcrash:/opt/snowcrash/level09$ 
```

Now we know that er have to do some retro engineering to understandwhat the binary does :
(strace does not give us a lot of information so we're gonna use string !)

```bash
level09@snowcrash:/opt/snowcrash/level09$ strings da5id | grep -E '[a-z]{3,}'

...
Rate limit exceeded.
Token format error.
checking byte %d...
accepted fp=%08x
rejected at byte %u fp=%08x
Invalid token.
/home/flag09/.flag
access error
Flag: %s
Token contains non-printable characters.
Token does not meet policy requirements.
Iheartpwnage
```
We grep -E '[a-z]{3,}' to delete all artifacts of machine code 
After analyzingthe result we see 1 weird things Iheartpwnage with some luck it's the token lets try :

```bash
level09@snowcrash:/opt/snowcrash/level09$ ./da5id Iheartpwnage
checking byte 0...
checking byte 1...
checking byte 2...
checking byte 3...
checking byte 4...
checking byte 5...
checking byte 6...
checking byte 7...
checking byte 8...
checking byte 9...
checking byte 10...
checking byte 11...
TOKEN ACCEPTED.
Flag: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```