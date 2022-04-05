---
title: Bash
subtitle: best practices
layout: plain
---

Arrays
------

### Declaration

<div class="row">
  <div class="col-md-6" markdown="1">

```bash
local -a xs=()
declare -a xs=()
local -A xs=()
declare -A xs=()

# Works with nounset:
echo "${#xs[@]}"
```

  </div>
  <div class="col-md-6" markdown="1">

```bash
local -a xs
declare -a xs
local -A xs
declare -A xs

# Doesn't work with nounset:
echo "${#xs[@]}"
```

  </div>
</div>

### Expansion

<div class="row">
  <div class="col-md-6" markdown="1">

```bash
func ${arr[@]+"${arr[@]}"}
```

  </div>
  <div class="col-md-6" markdown="1">

```bash
# Doesn't work with nounset:
func "${arr[@]}"
# Doesn't work properly with `declare -a arr=('')`:
func "${arr[@]+"${arr[@]}"}"
```

  </div>
</div>

### `unset`

<div class="row">
  <div class="col-md-6" markdown="1">

```bash
unset -v 'arr[x]'
unset -v 'arr[$i]'
```

  </div>
  <div class="col-md-6" markdown="1">

```bash
# May break due to globbing:
unset -v arr[x]
# In addition, possible quoting problem:
unset -v arr[$i]
# Doesn't work for some reason:
unset -v 'arr["x"]'
unset -v 'arr["]"]'
# Also rejected:
unset -v 'arr["$i"]'

# An insightful discussion on the topic:
# https://lists.gnu.org/archive/html/help-bash/2016-09/msg00020.html
```

  </div>
</div>

`errexit`
---------

I hate this feature, and I especially hate people who prefer "standards" over
useful behaviour.

### Command substitution

<div class="row">
  <div class="col-md-6" markdown="1">

```bash
# Without this, bar will be executed w/ errexit disabled!
shopt -s inherit_errexit

bar() {
    false
    echo 'should never see this' >&2
}

bar_output="$( bar )"
foo "$bar_output"
```

  </div>
  <div class="col-md-6" markdown="1">

```bash
bar() {
    false
    echo 'should never see this' >&2
}

# Even with errexit, foo will still get executed.
# More than that, the script will print 'should never see this'!
foo "$( bar )"
```

  </div>
</div>

### Process substitution

<div class="row">
  <div class="col-md-6" markdown="1">

```bash
shopt -s lastpipe

command | while IFS= read -r line; do
    process_line "$line"
done
```

  </div>
  <div class="col-md-6" markdown="1">

```bash
# Without lastpipe, you cannot pipe into read:
command | while IFS= read -r line; do
    process_line "$line"
done
```

```bash
# errexit doesn't work here no matter what:
while IFS= read -r line; do
    process_line "$line"
done < <( command )
echo 'should never see this'
```

```bash
# This would break if $output contains the \0 byte:
output="$( command )"

while IFS= read -r line; do
    process_line "$line"
done <<< "$output"
```

  </div>
</div>

### Functions

<div class="row">
  <div class="col-md-6" markdown="1">

```bash
foo() {
    false
    echo 'should never see this' >&2
}

foo
echo ok
```

  </div>
  <div class="col-md-6" markdown="1">

```bash
# foo will still print 'should never see this'.
if foo; then
    echo ok
fi

# Same below.
foo && echo ok
foo || echo ok
```

  </div>
</div>
