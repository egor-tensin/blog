---
title: Bash
subtitle: best practices
---
(Associative) arrays
--------------------

### Declaration

`"${#xs[@]}"` doesn't work with `nounset` if `xs` wasn't defined, i.e. was
declared with either of

    local -a xs
    declare -a xs
    local -A xs
    declare -A xs

Therefore, if you want to extract the length of an array, append `=()` to the
statements above.

    local -a xs=()
    declare -a xs=()
    ...

And now `"${#xs[@]}"` works with `nounset`.
It doesn't affect expansion (see below) though.

### Expansion

#### Do

    func ${arr[@]+"${arr[@]}"}

#### Don't

    func "${arr[@]}"                # Doesn't work with `nounset`.
    func "${arr[@]+"${arr[@]}"}"    # Doesn't work properly with `declare -a arr=('')`.

### `unset`

#### Do

    unset -v 'arr[x]'
    unset -v 'arr[$i]'

#### Don't

    unset -v arr[x]         # May break due to globbing.
    unset -v arr[$i]        # The same as above + a possible problem with quotation.
    unset -v 'arr["x"]'     # Doesn't work for some reason.
    unset -v 'arr["]"]'     # The same as above; just highlighting the problem with funny characters in array indices.
    unset -v 'arr["$i"]'    # Also rejected.

    # An insightful discussion on the topic: https://lists.gnu.org/archive/html/help-bash/2016-09/msg00020.html.

`errexit`
---------

I hate this feature, and I especially hate people who prefer "standards" over
useful behaviour.

### Command substitution

#### Do

    shopt -s inherit_errexit    # Without this, bar will be executed w/ errexit disabled!

    bar() {
        false
        echo 'should never see this' >&2
    }

    bar_output="$( bar )"
    foo "$bar_output"

#### Don't

    bar() {
        false
        echo 'should never see this' >&2
    }

    foo "$( bar )"    # Even with errexit, foo will still get executed.
                      # More than that, the script will print 'should never see this'!

### Process substitution

#### Do

    output="$( command )"

    while IFS= read -r line; do
        process_line "$line"
    done <<< "$output"

#### Don't

    # This causes some bash insanity where you cannot change directories or set
    # variables inside a loop: http://mywiki.wooledge.org/BashFAQ/024
    command | while IFS= read -r line; do
        process_line "$line"
    done

    # errexit doesn't work here no matter what:
    while IFS= read -r line; do
        process_line "$line"
    done < <( command )
    echo 'should never see this'

### Functions

#### Do

    foo() {
        false
        echo 'should never see this' >&2
    }

    foo
    echo ok

#### Don't

    if foo; then
        echo ok       # foo will still print 'should never see this'.
    fi

    foo && echo ok    # Same here.
    foo || echo ok
