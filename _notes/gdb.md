---
title: GDB
subtitle: cheat sheet
links:
  - {rel: stylesheet, href: 'assets/css/gdb.css'}
---
Core dumps
----------

* Where are my core dumps?

      cat /proc/sys/kernel/core_pattern

* Put core dumps in a directory:

      mkdir /coredumps
      chmod 0777 /coredumps
      echo '/coredumps/core.%e.%p' | tee /proc/sys/kernel/core_pattern

* Still no dumps :-(

      ulimit -c unlimited

* If dumps are piped to systemd-coredump, you can examine them using
`coredumpctl`.

  <div markdown="1" class="table-responsive">
  | List dumps            | `coredumpctl`
  | Debug the last dump   | `coredumpctl gdb`
  | Extract the last dump | `coredumpctl dump -o core`
  {: .table .table-bordered .table-condensed }
  </div>

.gdbinit
--------

    # Without these, gdb is hardly usable:
    set pagination off
    set confirm off
    set print pretty on

    # Save history:
    set history save on
    set history filename ~/.gdb-history
    set history size 10000

Basics
------

<div markdown="1" class="table-responsive">

| Run                     | `r`
| Continue                | `c`
| Create breakpoint       | `b FUNC`
| List breakpoints        | `i b`
| Disable breakpoint      | `dis N`
| Enable breakpoint       | `en N`
| Delete breakpoint       | `d N`
| Call stack              | `bt`
| Call stack: all threads | `thread apply all bt`
| Go to frame             | `f N`
| Disassemble             | `disas FUNC`
| Step over line          | `n`
| Step over instruction   | `si`
| Step out of frame       | `fin`
{: .table .table-bordered .table-condensed }

</div>

Hint: put this in your ~/.gdbinit and use `bta` as a shortcut:

    define bta
        thread apply all backtrace
    end

Data inspection
---------------

<div markdown="1" class="table-responsive">

| Disassemble 5 instructions    | `x/5i 0xdeadbeef`
| Print a 64-bit address        | `x/1xg 0xdeadbeef`
| Print a 32-bit address        | `x/1xw 0xdeadbeef`
| Print anything                | `p sa->__sigaction_handler.sa_handler`
| Describe a type               | `ptype struct sigaction`
| Describe a type with offsets  | `ptype /o struct sigaction`
| Disassemble all code sections | `objdump -d /proc/self/exe`
| Disassemble a single section  | `objdump -d -j .init /proc/self/exe`
| Display the section contents  | `objdump -s -j .data /proc/self/exe`
{: .table .table-bordered .table-condensed }

</div>

Hint: put this in your ~/.gdbinit:

    define xxd
        dump binary memory /tmp/dump.bin $arg0 ((char *)$arg0)+$arg1
        shell xxd -groupsize 1 /tmp/dump.bin
        shell rm -f /tmp/dump.bin
    end

You can then use `xxd ADDR LEN` to display, in my opinion, the best formatting
for memory dumps:

    (gdb) xxd main 24
    00000000: f3 0f 1e fa 41 57 41 89 ff bf 05 00 00 00 41 56  ....AWA.......AV
    00000010: 49 89 f6 41 55 41 54 55                          I..AUATU

Debuginfod
----------

If your distribution provides a Debuginfod server, use it!
For example, see [Arch], [Debian], [Fedora].
In ~/.gdbinit, add

    set debuginfod enabled on

[Arch]: https://wiki.archlinux.org/title/Debuginfod
[Debian]: https://wiki.debian.org/Debuginfod
[Fedora]: https://fedoraproject.org/wiki/Debuginfod


Intel syntax
------------

This is just me being a baby duck.
In ~/.gdbinit:

    set disassembly-flavor intel

With `objdump`:

    objdump -Mintel -d /proc/self/exe
