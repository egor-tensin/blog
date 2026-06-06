#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Select all process IDs that are _not_ children of PID 2, [kthreadd].
pids="$( ps -o pid --no-headers --ppid 2 -p 2 --deselect )"

for pid in $pids; do
	cmdline="$( cat "/proc/$pid/cmdline" | tr '\0' ' ' )" || continue
	echo ------------------------------------------------------------------
	echo "PID: $pid"
	echo "Command line: $cmdline"
	echo ------------------------------------------------------------------
	gdb -p "$pid" -x sleep.gdb -batch &
done

wait
