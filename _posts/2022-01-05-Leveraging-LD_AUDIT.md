---
title: 'Leveraging LD_AUDIT to Beat the Traditional Linux Library Preloading Technique - repost'
date: '2022-01-05T01:22:20+02:00'
categories: [Linux]
tags: ['Linux', 'LD_AUDIT', 'LD_PRELOAD', 'evasion', 'library hijacking', 'preloading', 'ld.so']
---
About a year ago I while I was going through the code of the standard library loader, `ld.so`, I encountered an interesting auditing API.

Soon I found out that this API is very handy and powerful - only by setting an environment variable named `LD_AUDIT`, it will load my own library to a process in a very early stage in its initialization.

This was genuinely fascinating for me because up until then, the most commonly used technique was using `LD_PRELOAD` for library preloading, and `LD_AUDIT` was unknown

I managed to both create a rootkit - by hijacking library calls, and also defend against `LD_PRELOAD` - by blocking its loading

As those are unheard-of techniques in the Linux cyber-security community, I wrote a blog post about it through my employer, SentinelOne, and you can read all about it there 🙂

[link](https://s1.ai/LD_AUDIT)

Enjoy!

### External links and further reading on the topic:

LD_PRELOAD trick:<br />
<https://www.goldsborough.me/c/low-level/kernel/2016/08/29/16-48-53-the_-ld_preload-_trick/>

The man page for the loader’s auditing API:<br />
<https://man7.org/linux/man-pages/man7/rtld-audit.7.html>

The loader’s source code is inside glibc’s repository:<br />
<https://code.woboq.org/userspace/glibc/><br />
The most relevant files are `rtld.c` and all `dl-*.c`

Libprocesshider repository:<br />
<https://github.com/gianlucaborello/libprocesshider>

More on process hiding and LD_PRELOAD:<br />
<https://sysdig.com/blog/hiding-linux-processes-for-fun-and-profit/>

Thorough explanation on symbol resolving: <br />
<https://ypl.coffee/dl-resolve/>

MITRE’s technique on LD_PRELOAD:<br />
<https://attack.mitre.org/techniques/T1574/006/>

Patch the loader to disable preloading: <br />
<https://github.com/hc0d3r/ldpreload-disable>

libpreloadvaccine repository and article:<br />
<https://github.com/ForensicITGuy/libpreloadvaccine><br />
<https://medium.com/forensicitguy/whitelisting-ld-preload-for-fun-and-no-profit-98dfea740b9>
