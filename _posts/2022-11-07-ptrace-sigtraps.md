---
title: 'Fun with ptrace: SIGTRAPs galore'
date: 2022-11-07 13:00 +0100
---
When using `PTRACE_ATTACH` the `ptrace` mechanism reuses SIGTRAP for a number
of things by default.
This makes it unnecessarily hard to distinguish regular traps possibly caused
by breakpoints we might place from other events.

1. After `ptrace(PTRACE_SYSCALL)`, syscall-stops will be reported as SIGTRAPs.

   ```c
   int status;

   ptrace(PTRACE_SYSCALL, pid, 0, 0);
   waitpid(pid, &status, 0);

   if (WIFSTOPPED(status) && WSTOPSIG(status) == SIGTRAP) {
       /* We don't know if the tracee has just entered/exited a syscall or
        * received a regular SIGTRAP (could be caused by a breakpoint we
        * placed). */
   }
   ```

   This is fixed by using the `PTRACE_O_TRACESYSGOOD` option.

   ```c
   int status;

   ptrace(PTRACE_SETOPTIONS, pid, 0, PTRACE_O_TRACESYSGOOD);
   ptrace(PTRACE_SYSCALL, pid, 0, 0);
   waitpid(pid, &status, 0);

   if (WIFSTOPPED(status) && WSTOPSIG(status) == (SIGTRAP | 0x80)) {
       /* We know for sure that the tracee has just entered/exited a
        * syscall. */
   }
   ```

2. Every `execve` call will be reported as a SIGTRAP.

   ```c
   int status;

   ptrace(PTRACE_CONT, pid, 0, 0);
   waitpid(pid, &status, 0);

   if (WIFSTOPPED(status) && WSTOPSIG(status) == SIGTRAP) {
       /* We don't know if the tracee just called execve() or received a
        * regular SIGTRAP (could be caused by a breakpoint we placed). */
   }
   ```

   This is fixed by using the `PTRACE_O_TRACEEXEC` option.

   ```c
   int status;

   ptrace(PTRACE_SETOPTIONS, pid, 0, PTRACE_O_TRACEEXEC);
   ptrace(PTRACE_CONT, pid, 0, 0);
   waitpid(pid, &status, 0);

   if (WIFSTOPPED(status) && status >> 8 == (SIGTRAP | PTRACE_EVENT_EXEC << 8)) {
       /* We know for sure that the tracee has just called execve(). */
   }
   ```

   This point doesn't apply to tracees attached using `PTRACE_SEIZE`.
   {: .alert .alert-info }

As you can see, you should always use at least the `PTRACE_O_TRACESYSGOOD` and
`PTRACE_O_TRACEEXEC` options to be able to distinguish between SIGTRAPs.
