---
title: Pause all userspace processes
snippets_root_directory: snippets/gdb_sleep_all
snippets_language: bash
snippets:
  main:
    - gdb_sleep_all.sh
  gdb:
    - sleep.gdb
---
If you need to debug some kind of monitoring system (or just have some fun),
you might want to pause all userspace processes for a certain number of seconds
(to measure delays, etc.).

You can easily do this using GDB like this:

{% include jekyll-theme/snippets/section.html section_id='main' %}

sleep.gdb is a very simple GDB script; it basically sleeps for a determined
amount of seconds:

{% include jekyll-theme/snippets/section.html section_id='gdb' %}

You can simply run

    sudo ./gdb_sleep_all.sh

and all of your userspace processes should be frozen for 30 seconds.

On a couple of servers, this worked quite well; not so well on my laptop with
Xfce installed.
Obviously, this would require a bit of work to adapt for containers as well.
Otherwise, pretty neat, huh?
