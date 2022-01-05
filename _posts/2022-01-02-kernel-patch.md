---
title: 'Committing code to the Linux Kernel &#8211; from a stuck process to a git commit'
date: '2022-01-02T23:31:28+02:00'
categories: [Linux]
tags: ['Linux', 'kernel', 'binfmt_misc', 'Submit Patch']
img_path: /assets/img/kernel-patch
---
Earlier in 2021, about March, my own code got into the Linux kernel!  
Long story short, I found a bug in some binary execution handling component called `binfmt_misc`, got to the bottom of it and fixed it, suggested a patch, and it got applied 🙂

You can check out the commit here:

<https://github.com/torvalds/linux/commit/e7850f4d844e0acfac7e570af611d89deade3146>

As a big Linux enthusiast, you can just imagine how excited I’ve been when I saw this:

![](image.png)

Now I can retire in peace.

The long story:

  
I have been working on an educational Linux challenge, and I was trying to understand better the kernel component `binfmt_misc` for a specific level I had in mind.

For a brief explanation on the component, here is a it’s [Wikipedia page](https://en.wikipedia.org/wiki/Binfmt_misc):

*“* **binfmt\_misc** (*Miscellaneous Binary Format*) is a capability of the [Linux kernel](https://en.wikipedia.org/wiki/Linux_kernel) which allows arbitrary [executable file formats](https://en.wikipedia.org/wiki/Executable_file_format) to be recognized and passed to certain [user space](https://en.wikipedia.org/wiki/User_space) applications, such as [emulators](https://en.wikipedia.org/wiki/Emulator) and [virtual machines](https://en.wikipedia.org/wiki/Virtual_machine).<sup>[\[1\]](https://en.wikipedia.org/wiki/Binfmt_misc#cite_note-1)</sup> It is one of a number of binary format handlers in the kernel that are involved in preparing a user-space program to run.*“*

So this component allows any program to register a custom binary handler, according to some file name extension or file header magic the program defines.  
Then, upon the execution of the binary, the `binfmt_misc` component will identify the defined program and will pass it the handling of the execution, instead of the more commonly known ELF handler or bash script handler.

Ok, so I was messing around with registering a new binary handler, by echoing some input into a file named `register` in the binfmt filesystem but for some reason.. the process was stuck and didn’t return. I tried to terminate it brutally with “kill -9”, but to my surprise it didn’t respond! A system reboot was necessary to recover this process 😛

This is my input in bash:

```bash
echo ":iiiii:E::ii::/proc/sys/fs/binfmt_misc/bla:F" > /proc/sys/fs/binfmt_misc/register
```

As you can see, the kill signal is sent **successfully**, but no response from bash (from which I executed the ‘echo’ builtin command)

![The immortal bash](image-1.png)
_The immortal bash_
Alrighttt, some interesting behavior from the OS, don’t you think?

Let’s get digging

`/proc/sys/fs/binfmt_misc/register` isn’t a standard file in the filesystem.  
It is actually a mount point (mounted by default by many standard Linux distributions):

![binfmt mount point](image-2.png)
_binfmt mount point_
binfmt mount pointThen binfmt\_misc is also.. a filesystem! Or more accurately, a pseudo-filesystem, which implements an interface to communicate with the binfmt kernel component from user-space 🙂

Ok, so what is the `register` file and what is the string I just echoed means?  
From a [documentation ](https://www.kernel.org/doc/html/latest/admin-guide/binfmt-misc.html)written by kernel.org:

“To actually register a new binary type, you have to set up a string looking like `:name:type:offset:magic:mask:interpreter:flags` (where you can choose the `:` upon your needs) and echo it to `/proc/sys/fs/binfmt_misc/register`.”

In my input to the file, the name, type, offset, magic, and mask are non-important, therefore we will take a look at how the interpreter – “bla”, a non-existent file in the pseudo-filesystem directory, and flags – ‘F’ (fix binary, more on that later) are all together causing the process freeze

Glasses on – reading the kernel code

The code behind the binfmt\_misc filesystem resides in the kernel source code under “fs/binfmt\_misc.c”. We can manually locate it because “fs” is the folder where most filesystem code resides 😀

Then, we can find the `file_operations` struct that is assigned to the file “register”:

```c
static const struct file_operations bm_register_operations = {
	.write		= bm_register_write,
	.llseek		= noop_llseek,
};

```

So according to the above struct, each time a “write” operation is called on the file, the function `bm_register_write` will be called.

After reading the function’s [code](https://github.com/torvalds/linux/blob/2347961b11d4079deace3c81dceed460c08a8fc1/fs/binfmt_misc.c#L644), there is nothing unusual at a first glance.

Now let’s spawn a kernel debuger, and find out what happens inside the kernel (there are a lot of great guide on how to do this, I used kdbg on qemu with buildroot).
Then we find the task (thread in the kernel) in which bash is stuck, and inspect it’s backtrace:

```stacktrace
0  schedule () at ./arch/x86/include/asm/current.h:15
1  0xffffffff81b51237 in rwsem_down_read_slowpath (sem=0xffff888003b202e0, count=<optimized out>, state=state@entry=2) at kernel/locking/rwsem.c:992
2  0xffffffff81b5150a in __down_read_common (state=2, sem=<optimized out>) at kernel/locking/rwsem.c:1213
3  __down_read (sem=<optimized out>) at kernel/locking/rwsem.c:1222
4  down_read (sem=<optimized out>) at kernel/locking/rwsem.c:1355
5  0xffffffff811ee22a in inode_lock_shared (inode=<optimized out>) at ./include/linux/fs.h:783
6  open_last_lookups (op=0xffffc9000022fe34, file=0xffff888004098600, nd=0xffffc9000022fd10) at fs/namei.c:3177
7  path_openat (nd=nd@entry=0xffffc9000022fd10, op=op@entry=0xffffc9000022fe34, flags=flags@entry=65) at fs/namei.c:3366
8  0xffffffff811efe1c in do_filp_open (dfd=<optimized out>, pathname=pathname@entry=0xffff8880031b9000, op=op@entry=0xffffc9000022fe34) at fs/namei.c:3396
9  0xffffffff811e493f in do_open_execat (fd=fd@entry=-100, name=name@entry=0xffff8880031b9000, flags=<optimized out>, flags@entry=0) at fs/exec.c:913
10 0xffffffff811e4a92 in open_exec (name=<optimized out>) at fs/exec.c:948
11 0xffffffff8124aa84 in bm_register_write (file=<optimized out>, buffer=<optimized out>, count=19, ppos=<optimized out>) at fs/binfmt_misc.c:682
12 0xffffffff811decd2 in vfs_write (file=file@entry=0xffff888004098500, buf=buf@entry=0xa758d0 ":iiiii:E::ii::i:CF
", count=count@entry=19, pos=pos@entry=0xffffc9000022ff10) at fs/read_write.c:603
13 0xffffffff811defda in ksys_write (fd=<optimized out>, buf=0xa758d0 ":iiiii:E::ii::i:CF
", count=19) at fs/read_write.c:658
14 0xffffffff81b49813 in do_syscall_64 (nr=<optimized out>, regs=0xffffc9000022ff58) at arch/x86/entry/common.c:46
15 0xffffffff81c0007c in entry_SYSCALL_64 () at arch/x86/entry/entry_64.S:120
```

We see that indeed the code is stuck in `binfmt_register_write` (11) when calling the function `open_exec` (10).  
Looks like down the road a shared lock is taken, probably on the file passed to `open_exec` (I verified it later), but the lock can’t be obtained, therefore the process waits.

So who takes a write lock in a manner that causes an actual deadlock?   
We should get back to `bm_register_write` (only relevant parts):

```c
static ssize_t bm_register_write(struct file *file, const char __user *buffer,
                   size_t count, loff_t *ppos)
{
    Node *e;
    struct inode *inode;
    struct super_block *sb = file_inode(file)->i_sb;
    struct dentry *root = sb->s_root, *dentry;
    int err = 0;

    e = create_entry(buffer, count); (1)
    ...
    inode_lock(d_inode(root)); (2)
    ...
    if (e->flags & MISC_FMT_OPEN_FILE) { (3)
        struct file *f;

        f = open_exec(e->interpreter); (4)
        if (IS_ERR(f)) {
            err = PTR_ERR(f);
            pr_notice("register: failed to install interpreter file %s\n", e->interpreter); (5)
            simple_release_fs(&bm_mnt, &entry_count);
            iput(inode);
            inode = NULL;
            goto out2;
        }
        e->interp_file = f;
    }

    ...

    err = 0;
out2:
    dput(dentry);
out: (6)
    inode_unlock(d_inode(root));

    ...
}
```

In (1), the entry is created, and the flags are populated.

In (2), a lock is taken on the whole filesystem root (!!!!). Alright, maybe this is it?

In (3) , we check the flags we provided in our input  
We can see in some inner [code](https://github.com/torvalds/linux/blob/2347961b11d4079deace3c81dceed460c08a8fc1/fs/binfmt_misc.c#L256) (called somewhere inside `create_entry`) that ‘F’ adds the flag `MISC_FMT_OPEN_FILE`, hence the “if” statement is true and we reach the code in (4), which is the only statement that calls `open_exec` in our code flow.

We call `open_exec` with an interpreter path inside the filesystem root, and even though the file does not exist, an inner code will try to acquire a read lock, but after a write lock is already locking it, the code will… wait.

We can be sure by running `dmesg` and observing that the message in (5) has never been reached.

In (6), the write lock is taken down, which is too late: the task is now waiting inside `open_exec` and the function will never return

In short, a write lock is taken on the filesystem root, and with a specific input we cause the same task to try and read in the same place before the lock is taken down, and a deadlock transpires

Gloves on – Patching the code

You can see my final patch at the [kernel’s Github](https://github.com/torvalds/linux/commit/e7850f4d844e0acfac7e570af611d89deade3146#diff-bf2e758056c3a407da85096cc54172c2f8ea3d3e252a6692934d494f30cc5198), which is generally very simple – I just moved the “if” block before the code locks the entire kernel, and some small variable definition and freeing accordingly.

Then I did the tiresome work to create the patch conforming to the guidelines and sent it as an email to the Linux Kernel Mailing List, and.. nothing.

It was the end of December 2020, and I thought that maybe the holidays are causing a delay, but January came by, and my mail wasn’t even acked by anyone.  
I sent another email, but still nothing…

Each section in the Kernel code has a dedicated maintainer, but the maintainer of `binfmt_misc.c` just didn’t reply 🤷‍♂️

I continued with my life, and then, in February 2021, I noticed that someone else has inserted a commit into `binfmt_misc.c` !  
I emailed the guy (‫deller@gmx.de‬‏) personally and asked for help, and he pointed out that this code section isn’t really maintained and I should address a guy named Andrew Morton, who picks up random patches and forwards them to Linus.

Deller gave me a small fix to the code and forwarded it to Andrew with an ack.

Then after a couple of days, and after hopping through many different git repositories (the Linux kernel code process is very complicated) my code got into the kernel, and acked by the one and only, Linus Torvalds!

The public email exchange can be found in the Linux Kernel Mailing List archive starting [here](https://lkml.org/lkml/2020/12/24/121)

But retirement is too early, so I hope this is not my last patch 😉
