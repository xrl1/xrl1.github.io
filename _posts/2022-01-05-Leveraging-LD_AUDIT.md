---
title: 'Leveraging LD_AUDIT to Beat the Traditional Linux Library Preloading Technique - repost'
date: '2022-01-05T00:49:58+02:00'

categories: [Linux]
tags: ['Linux', 'LD_AUDIT', 'LD_PRELOAD', 'evasion', 'library hijacking', 'preloading', 'ld.so']
---
About a year ago I while I was going through the code of the standard library loader, `ld.so`, I encountered an interesting auditing API.

Soon I found out that this API is very handy and powerful - only by setting an environment variable named `LD_AUDIT`, it will load my own library to a process in a very early stage in its initialization.

This was genuinely fascinating for me because up until then, the most commonly used technique was using `LD_PRELOAD` for library preloading, and `LD_AUDIT` was unknown

I managed to both create a rootkit - by hijacking library calls, and also defending against `LD_PRELOAD` - by blocking its loading

As those are unheard-of techniques in the Linux cyber-security community, I wrote a blog post about it through my employer, SentinelOne, and you can read all about it there 🙂

<https://s1.ai/LD_AUDIT>

Enjoy!
