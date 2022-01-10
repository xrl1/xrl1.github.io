---
title: 'My Simple Utility for Kernel Function Graph Tracing'
date: '2022-01-10T20:39:22+02:00'
categories: [Linux]
tags: ['Linux', 'Tracing', 'strace', 'trace-cmd', 'utilty']
---
Have you ever wondered how come `strace` is such a popular tool, while all it shows you are only the syscalls a program is calling and nothing more?

Well, in most cases it's enough. But sometimes, even rarely, a programmer will also want to inspect what happens under the kernel's hood inside the syscalls.

I have been investigating kernel behavior on some basic tasks, like module loading for example, so my mission was to figure out the code path that is taken inside the kernel upon a simple invocation of the `insmod` command.

`strace` wasn't very helpful: it only displayed a call for an `init_module` syscall, but I wanted the function graph inside it!

After some web searches, and I didn't find any simple tool fitted to my problem.

The closest thing was [trace-cmd](https://man7.org/linux/man-pages/man1/trace-cmd.1.html), which uses the `ftrace` API for the job and creates a function graph as I wish. 
But I need to run it in a separate shell from my traced program, and also pass it my program's PID, which is problematic for quickly exiting simple utilities like `insmod`.

As a result, and as any decent bored engineer would do, I created a wrapper utility to exactly fit my needs 😁

## Welcome `kernel_function_trace` !

 bad name, but `ktrace` was too presumptuous.

Shortly, it's 50 lines of a C-code wrapper around `trace-cmd`, with some forking and signaling (and a tiny bit of sleeping), that makes kernel function tracing a little bit easier

It wraps around any program the same way strace does:

```bash
./kernel_function_trace insmod my_kernel_module.ko
```

And saves the long function call graph to a file, which can be pretty-printed with `trace-cmd report` : 
```
root@ubuntu:~/work# trace-cmd report | grep -A 15 load_module
          insmod-18954 [002] 30213.994129: funcgraph_entry:                   |      load_module() {
          insmod-18954 [002] 30213.994130: funcgraph_entry:        0.593 us   |        find_sec();
          insmod-18954 [002] 30213.994131: funcgraph_entry:        0.681 us   |        get_next_modinfo();
          insmod-18954 [002] 30213.994132: funcgraph_entry:        0.480 us   |        find_sec();
          insmod-18954 [002] 30213.994132: funcgraph_entry:        0.497 us   |        find_sec();
          insmod-18954 [002] 30213.994133: funcgraph_entry:        0.490 us   |        find_sec();
          insmod-18954 [002] 30213.994134: funcgraph_entry:                   |        mod_verify_sig() {
          insmod-18954 [002] 30213.994134: funcgraph_entry:        0.213 us   |          mod_check_sig();
          insmod-18954 [002] 30213.994134: funcgraph_entry:                   |          verify_pkcs7_signature() {
          insmod-18954 [002] 30213.994135: funcgraph_entry:                   |            pkcs7_parse_message() {
          insmod-18954 [002] 30213.994135: funcgraph_entry:                   |              kmem_cache_alloc_trace() {
          insmod-18954 [002] 30213.994135: funcgraph_entry:                   |                _cond_resched() {
          insmod-18954 [002] 30213.994135: funcgraph_entry:        0.202 us   |                  rcu_all_qs();
          insmod-18954 [002] 30213.994136: funcgraph_exit:         0.571 us   |                }
          insmod-18954 [002] 30213.994136: funcgraph_entry:        0.202 us   |                should_failslab();
          insmod-18954 [002] 30213.994136: funcgraph_entry:        0.294 us   |                memcg_kmem_put_cache();
```

Voilà!

You can find it together with a fair README on my GitHub page:

<https://github.com/xrl1/kernel_function_trace>

Enjoy!
