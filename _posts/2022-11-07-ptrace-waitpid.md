---
title: 'Fun with ptrace: a waitpid pitfall'
date: 2022-11-07 12:00 +0100
---
When tracing a process using `ptrace`, one often uses the `waitpid` system call
to wait until something happens to the tracee.
It often goes like this (error handling is omitted for brevity):

```c
/* We have previously attached to tracee `pid`. */

int status;

waitpid(pid, &status, 0);

if (WIFEXITED(status)) {
    /* Tracee has exited. */
}
if (WIFSIGNALED(status)) {
    /* Tracee was killed by a signal. */
}
/* Tracee was stopped by a signal WSTOPSIG(status). */
```

What if a single thread is attached to multiple tracees?
Then we can use `-1` as the first argument to `waitpid`, and it will wait for
any child to change state.

```c
int status;
pid_t pid = waitpid(-1, &status, __WALL);
```

What's little known, however, is that `waitpid(-1)` will by default consume
status changes from other thread's children.
So if you have two tracer threads A and B, and each of them is attached to a
tracee, then thread A might consume thread B's tracee status change by calling
`waitpid(-1)`.

To avoid that, use the `__WNOTHREAD` flag.
That way, thread A will only consume status changes from its own children only.

```c
int status;
pid_t pid = waitpid(-1, &status, __WALL | __WNOTHREAD);
```

In my opinion, `__WNOTHREAD` should often be a default in well-structured
applications.
