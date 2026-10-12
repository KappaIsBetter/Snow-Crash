# snow-crash

## Project overview

`snow-crash` is the first CTF of the post-common-core 42 cursus. It consists of 11 mandatory exercises, numbered from 00 to 10, and 5 bonus levels. The goal of each level is to find the flag, allowing you access to the next one.

## Goals

It being the first project out of three, its main purpose is teaching us the fundamentals of CTF :
- Recon : Knowing who we are, our groups and our permissions.
- Enum : Finding services, interesting files and folders.
- Hypothesis : Trying to find the exploit's entrypoint, and testing to see the results.
- Exploit : The entrypoint found, try to exploit it to get the flag.

For each level, we are presented with a folder in `/opt/snowcrash` corresponding to our current level. Inside will be some interesting files that will help us reach the flag.

## Skills

To achieve all levels of `snow-crash`, we had to read the strings of ELFs, create compromised configuration files, helper scripts and injection scripts, and learn about Linux file permissions.