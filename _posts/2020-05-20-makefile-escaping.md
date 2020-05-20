---
title: Escaping characters in Makefile
excerpt: Making less error-prone.
---
I'm a big sucker for irrelevant neatpicks like properly quoting arguments in
shell scripts.
I've also recently started using GNU make as a substitute for one-line shell
scripts (so instead of a bunch of scripts like build.sh, deploy.sh, test.sh I
get to have a single Makefile and can just run `make build`, `make deploy`,
`make test`).

As a side note, there's an excellent [Makefile style guide] available on the
web.
I'm going to be using the prologue suggested in the guide in all Makefiles in
this post:

[Makefile style guide]: https://clarkgrubb.com/makefile-style-guide

```
MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c
```

`make` invokes a shell program to execute recipes.
As issues of properly escaping "special" characters are going to be discussed,
the choice of shell is very relevant.
The Makefiles in this post specify `bash` explicitly using the `SHELL`
variable, but the same rules should apply for all similar `sh`-like shells.

TL;DR
-----

* Quote command arguments in Makefiles using single quotes `'`.
* Don't use `'` and `$` in stuff like file paths/environment variable values,
and you're good to go.
* To escape `$(shell)` function output, define a helper function:

      escape = $(subst ','\'',$(1))

  You can then replace `'$(shell your-command arg1 arg2)'` with
`'$(call escape,$(shell your-command arg1 arg2))'`.
* To escape environment variable values, define another helper function:

      escape_var = $(call escape,$(value $(1)))

  You can then replace `'$(VAR_NAME)'` with `'$(call escape_var,VAR_NAME)'`.
* Don't override variables using `make var1=value1 var2=value2`, use your shell
instead: `var1=value1 var2=value2 make`.

Quoting arguments
-----------------

You should quote command arguments in `make` rule recipes, just like in shell
scripts.
This is to prevent a single argument from being expanded into multiple
arguments by the shell.

```
$ cat > Makefile
test_var := Same line?
export test_var

test:
	printf '%s\n' $(test_var)
	printf '%s\n' '$(test_var)'
	printf '%s\n' $$test_var
	printf '%s\n' "$$test_var"

$ make test
printf '%s\n' Same line?
Same
line?
printf '%s\n' 'Same line?'
Same line?
printf '%s\n' $test_var
Same
line?
printf '%s\n' "$test_var"
Same line?
```

This is quite often sufficient to write valid recipes.

One thing to note is that you shouldn't use double quotes `"` for quoting
arguments, as they might contain literal dollar signs `$`, interpreted by the
shell as variable references, which is not something you always want.

Escaping quotes
---------------

What if `test_var` included a single quote `'`?
In that case, even the quoted `printf` invocation would break because of the
mismatch.

```
$ cat > Makefile
test_var := Includes ' quote

test:
	printf '%s\n' '$(test_var)'

$ make test
printf '%s\n' 'Includes ' quote'
bash: -c: line 0: unexpected EOF while looking for matching `''
make: *** [Makefile:11: test] Error 2
```

One solution is to take advantage of how `bash` parses command arguments, and
replace every quote `'` by `'\''`.
This works because `bash` merges a string like `'Includes '\'' quote'` into
`Includes ' quote`.

```
$ cat > Makefile
escape = $(subst ','\'',$(1))

test_var := Includes ' quote

test:
	printf '%s\n' '$(call escape,$(test_var))'

$ make test
printf '%s\n' 'Includes '\'' quote'
Includes ' quote
```

Surprisingly, this works even in much more complicated cases.
You can have a recipe that executes a command that takes a whole other command
(with its own separate arguments) as an argument.
I guess the most common use case is doing something like `ssh 'rm -rf
$(junk_dir)'`, but I'll use nested `bash` calls instead for simplicity.

```
$ cat > Makefile
escape = $(subst ','\'',$(1))

test_var := Includes ' quote

echo_test_var := printf '%s\n' '$(call escape,$(test_var))'
bash_test_var := bash -c '$(call escape,$(echo_test_var))'

test:
	printf '%s\n' '$(call escape,$(test_var))'
	bash -c '$(call escape,$(echo_test_var))'
	bash -c '$(call escape,$(bash_test_var))'

$ make test
printf '%s\n' 'Includes '\'' quote'
Includes ' quote
bash -c 'printf '\''%s\n'\'' '\''Includes '\''\'\'''\'' quote'\'''
Includes ' quote
bash -c 'bash -c '\''printf '\''\'\'''\''%s\n'\''\'\'''\'' '\''\'\'''\''Includes '\''\'\'''\''\'\''\'\'''\'''\''\'\'''\'' quote'\''\'\'''\'''\'''
Includes ' quote
```

That's somewhat insane, but it works.

Shell output
------------

The `shell` function is one of the two most common ways to communicate with the
outside world in a Makefile (the other being environment variables).
This little `escape` function we've defined is actually sufficient to deal with
the output of the `shell` function safely.

```
$ cat > Makefile
escape = $(subst ','\'',$(1))

cwd := $(shell basename -- "$$( pwd )")
export cwd

echo_cwd := printf '%s\n' '$(call escape,$(cwd))'
bash_cwd := bash -c '$(call escape,$(echo_cwd))'

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(cwd))'
	@printf '%s\n' "$$cwd"
	@bash -c '$(call escape,$(echo_cwd))'
	@bash -c '$(call escape,$(bash_cwd))'

$ ( mkdir -p -- "Includes ' quote" && cd -- "Includes ' quote" && make -f ../Makefile test ; )
Includes ' quote
Includes ' quote
Includes ' quote
Includes ' quote

$ ( mkdir -p -- 'Maybe a comment #' && cd -- 'Maybe a comment #' && make -f ../Makefile test ; )
Maybe a comment #
Maybe a comment #
Maybe a comment #
Maybe a comment #

$ ( mkdir -p -- 'Variable ${reference}' && cd -- 'Variable ${reference}' && make -f ../Makefile test ; )
Variable ${reference}
Variable ${reference}
Variable ${reference}
Variable ${reference}
```

Environment variables
---------------------

Makefiles often have parameters that modify their behaviour.
The most common example is doing something like `make install
PREFIX=/somewhere/else`, where the `PREFIX` argument overrides the default
value "/usr/local".
These parameters are often defined in a Makefile like this:

```
param_name ?= Default value
```

They should be quoted when passed to external commands, of course.
To prevent mismatched quotes, the `escape` function might seem useful, but in
case of environment variables, a complication arises when they contain dollar
signs `$`.
`make` variables may contain references to other variables, and they're
expanded recursively either when defined (for `:=` assignments) or when used
(in all other cases, including `?=`).


```
$ cat > Makefile
escape = $(subst ','\'',$(1))

test_var ?= This is safe.
export test_var

echo_test_var := printf '%s\n' '$(call escape,$(test_var))'
bash_test_var := bash -c '$(call escape,$(echo_test_var))'

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(test_var))'
	@printf '%s\n' "$$test_var"
	@bash -c '$(call escape,$(echo_test_var))'
	@bash -c '$(call escape,$(bash_test_var))'

$ test_var='Variable ${reference}' make test
Makefile:18: warning: undefined variable 'reference'
Variable
Variable ${reference}
Variable
Variable
```

Here, `$(test_var)` is expanded recursively, substituting an empty string for
the `${reference}` part.
One attempt to solve this is to escape the dollar sign in the variable value,
but that breaks the `"$$test_var"` case:

```
$ test_var='Variable $${reference}' make test
Variable ${reference}
Variable $${reference}
Variable ${reference}
Variable ${reference}
```

A working solution would be to use the `escape` function on the unexpanded
variable value.
Turns out, you can do just that using the `value` function in `make`.

```
$ cat > Makefile
escape = $(subst ','\'',$(1))
escape_var = $(call escape,$(value $(1)))

test_var ?= This is safe.
export test_var

echo_test_var := printf '%s\n' '$(call escape_var,test_var)'
bash_test_var := bash -c '$(call escape_var,echo_test_var)'

.PHONY: test
test:
	@printf '%s\n' '$(call escape_var,test_var)'
	@printf '%s\n' "$$test_var"
	@bash -c '$(call escape_var,echo_test_var)'
	@bash -c '$(call escape_var,bash_test_var)'

$ test_var='Variable ${reference}' make test
Variable ${reference}
Variable ${reference}
Variable ${reference}
Variable ${reference}
```

You can still use the original `escape` function to escape `shell` output.

One thing to note is that I couldn't find a way to prevent variable values from
being expanded when [overriding variables] on the command line.
For example, this doesn't work:

[overriding variables]: https://www.gnu.org/software/make/manual/html_node/Overriding.html#Overriding

```
$ make test test_var='Variable ${reference}'
make: warning: undefined variable 'reference'
Variable ${reference}
Variable
Variable ${reference}
Variable ${reference}

$ make test test_var='Variable $${reference}'
Variable $${reference}
Variable ${reference}
Variable $${reference}
Variable $${reference}
```

As a workaround, set parameter values using your shell: `var_name=value make
...`.
