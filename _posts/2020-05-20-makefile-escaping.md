---
title: Escaping characters in Makefile
excerpt: Making less error-prone.
---
I'm a big sucker for irrelevant nitpicks like properly quoting arguments in
shell scripts.
I've also recently started using GNU make as a substitute for one-line shell
scripts (so instead of a bunch of scripts like build.sh, deploy.sh, test.sh I
get to have a single Makefile and can just run `make build`, `make deploy`,
`make test`).

As a side note, there's an excellent [Makefile style guide] available on the
web.
I'm going to be using a slightly modified prologue suggested in the guide in
all Makefiles in this post:

[Makefile style guide]: https://clarkgrubb.com/makefile-style-guide

```
MAKEFLAGS += --no-builtin-rules --no-builtin-variables --warn-undefined-variables
unexport MAKEFLAGS
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
```

`make` invokes a shell program to execute recipes.
As issues of properly escaping "special" characters are going to be discussed,
the choice of shell is very relevant.
The Makefiles in this post specify `bash` explicitly using the `SHELL`
variable, but the same rules should apply for all similar `sh`-like shells.

TL;DR
-----

Visit [this page] for an all-in-one Makefile template.
{: .alert .alert-info }

[this page]: {{ site.baseurl }}{% link _notes/makefile.md %}

* Put the prologue above at the top of your Makefile.
* Quote command arguments in Makefiles using single quotes `'`.
* Define a helper function:

      escape = $(subst ','\'',$(1))

  Instead of:

      test:
          echo '$(var)'

  do

      test:
          echo '$(call escape,$(var))'

* If you use environment variables in your Makefile (or you override variables
on the command line), add the following lengthy snippet:

      define noexpand
      ifeq ($$(origin $(1)),environment)
          $(1) := $$(value $(1))
      endif
      ifeq ($$(origin $(1)),environment override)
          $(1) := $$(value $(1))
      endif
      ifeq ($$(origin $(1)),command line)
          override $(1) := $$(value $(1))
      endif
      endef

  Then `eval` the `noexpand` function output for every possibly overridden
variable or a used environment variable:

      param_with_default_value ?= Default value
      $(eval $(call noexpand,param_with_default_value))

      $(eval $(call noexpand,used_environment_variable))

Quoting arguments
-----------------

You should quote command arguments in `make` rule recipes, just like in shell
scripts.
This is to prevent a single argument from being expanded into multiple
arguments by the shell.

{% capture out1 %}
# Prologue goes here...

test_var := Same line?
export test_var

test:
	@printf '%s\n' $(test_var)
	@printf '%s\n' '$(test_var)'
	@printf '%s\n' $$test_var
	@printf '%s\n' "$$test_var"
{% endcapture %}

{% capture out2 %}
Same
line?
Same line?
Same
line?
Same line?
{% endcapture %}

{% include jekyll-theme/shell.html cmd='cat Makefile' out=out1 %}
{% include jekyll-theme/shell.html cmd='make test' out=out2 %}

This is quite often sufficient to write valid recipes.

One thing to note is that you shouldn't use double quotes `"` for quoting
arguments, as they might contain literal dollar signs `$`, interpreted by the
shell as variable references, which is not something you always want.

Escaping quotes
---------------

What if `test_var` included a single quote `'`?
In that case, even the quoted `printf` invocation would break because of the
mismatch.

{% capture out1 %}
# Prologue goes here...

test_var := Includes ' quote

test:
	printf '%s\n' '$(test_var)'
{% endcapture %}

{% capture out2 %}
printf '%s\n' 'Includes ' quote'
bash: -c: line 0: unexpected EOF while looking for matching `''
make: *** [Makefile:11: test] Error 2
{% endcapture %}

{% include jekyll-theme/shell.html cmd='cat Makefile' out=out1 %}
{% include jekyll-theme/shell.html cmd='make test' out=out2 %}

One solution is to take advantage of how `bash` parses command arguments, and
replace every quote `'` by `'\''`.
This works because `bash` merges a string like `'Includes '\'' quote'` into
`Includes ' quote`.

{% capture out1 %}
# Prologue goes here...

escape = $(subst ','\'',$(1))

test_var := Includes ' quote

test:
	printf '%s\n' '$(call escape,$(test_var))'
{% endcapture %}

{% capture out2 %}
printf '%s\n' 'Includes '\'' quote'
Includes ' quote
{% endcapture %}

{% include jekyll-theme/shell.html cmd='cat Makefile' out=out1 %}
{% include jekyll-theme/shell.html cmd='make test' out=out2 %}

Surprisingly, this works even in much more complicated cases.
You can have a recipe that executes a command that takes a whole other command
(with its own separate arguments) as an argument.
I guess the most common use case is doing something like `ssh 'rm -rf
$(junk_dir)'`, but I'll use nested `bash` calls instead for simplicity.

{% capture out1 %}
# Prologue goes here...

escape = $(subst ','\'',$(1))

test_var := Includes ' quote

echo_test_var := printf '%s\n' '$(call escape,$(test_var))'
bash_test_var := bash -c '$(call escape,$(echo_test_var))'

test:
	printf '%s\n' '$(call escape,$(test_var))'
	bash -c '$(call escape,$(echo_test_var))'
	bash -c '$(call escape,$(bash_test_var))'
{% endcapture %}

{% capture out2 %}
printf '%s\n' 'Includes '\'' quote'
Includes ' quote
bash -c 'printf '\''%s\n'\'' '\''Includes '\''\'\'''\'' quote'\'''
Includes ' quote
bash -c 'bash -c '\''printf '\''\'\'''\''%s\n'\''\'\'''\'' '\''\'\'''\''Includes '\''\'\'''\''\'\''\'\'''\'''\''\'\'''\'' quote'\''\'\'''\'''\'''
Includes ' quote
{% endcapture %}

{% include jekyll-theme/shell.html cmd='cat Makefile' out=out1 %}
{% include jekyll-theme/shell.html cmd='make test' out=out2 %}

That's somewhat insane, but it works.

Shell output
------------

The `shell` function is one of the two most common ways to communicate with the
outside world in a Makefile (the other being environment variables).
This little `escape` function we've defined is actually sufficient to deal with
the output of the `shell` function safely.

{% capture out1 %}
# Prologue goes here...

escape = $(subst ','\'',$(1))

cwd := $(shell basename -- "$$( pwd )")

simple_var := Simple value
composite_var := Composite value - $(simple_var) - $(cwd)

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(cwd))'
	@printf '%s\n' '$(call escape,$(composite_var))'
{% endcapture %}

{% capture cmd2 %}
mkdir "Includes ' quote" && \
    cd "Includes ' quote" && \
    make -f ../Makefile test
{% endcapture %}
{% capture out2 %}
Includes ' quote
Composite value - Simple value - Includes ' quote
{% endcapture %}

{% capture cmd3 %}
mkdir 'Maybe a comment #' && \
    cd 'Maybe a comment #' && \
    make -f ../Makefile test
{% endcapture %}
{% capture out3 %}
Maybe a comment #
Composite value - Simple value - Maybe a comment #
{% endcapture %}

{% capture cmd4 %}
mkdir 'Variable ${reference}' && \
    cd 'Variable ${reference}' && \
    make -f ../Makefile test
{% endcapture %}
{% capture out4 %}
Variable ${reference}
Composite value - Simple value - Variable ${reference}
{% endcapture %}

{% include jekyll-theme/shell.html cmd='cat Makefile' out=out1 %}
{% include jekyll-theme/shell.html cmd=cmd2 out=out2 %}
{% include jekyll-theme/shell.html cmd=cmd3 out=out3 %}
{% include jekyll-theme/shell.html cmd=cmd4 out=out4 %}

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

They should be `escape`d and quoted when passed to external commands, of
course.
However, things get complicated when they contain dollar signs `$`.
`make` variables may contain references to other variables, and they're
expanded recursively either when defined (for `:=` assignments) or when used
(in all other cases, including `?=`).

{% capture out1 %}
# Prologue goes here...

escape = $(subst ','\'',$(1))

test_var ?= This is safe.
export test_var

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(test_var))'
	@printf '%s\n' "$$test_var"
{% endcapture %}

{% capture cmd2 %}
test_var='Variable ${reference}' make test
{% endcapture %}
{% capture out2 %}
Makefile:15: warning: undefined variable 'reference'
Variable
Variable ${reference}
{% endcapture %}

{% include jekyll-theme/shell.html cmd='cat Makefile' out=out1 %}
{% include jekyll-theme/shell.html cmd=cmd2 out=out2 %}

Here, `$(test_var)` is expanded recursively, substituting an empty string for
the `${reference}` part.
One attempt to solve this is to escape the dollar sign in the variable value,
but that breaks the `"$$test_var"` case:

{% capture cmd1 %}
test_var='Variable $${reference}' make test
{% endcapture %}
{% capture out1 %}
Variable ${reference}
Variable $${reference}
{% endcapture %}

{% include jekyll-theme/shell.html cmd=cmd1 out=out1 %}

A working solution would be to use the `escape` function on the unexpanded
variable value.
Turns out, you can do just that using the `value` function in `make`.

{% capture out1 %}
# Prologue goes here...

escape = $(subst ','\'',$(1))

test_var ?= This is safe.
test_var := $(value test_var)
export test_var

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(test_var))'
	@printf '%s\n' "$$test_var"
{% endcapture %}

{% capture cmd2 %}
test_var="Quote '"' and variable ${reference}' make test
{% endcapture %}
{% capture out2 %}
Quote ' and variable ${reference}
Quote ' and variable ${reference}
{% endcapture %}

{% include jekyll-theme/shell.html cmd='cat Makefile' out=out1 %}
{% include jekyll-theme/shell.html cmd=cmd2 out=out2 %}

This doesn't quite work though when [overriding variables] on the command line.
For example, this doesn't work:

[overriding variables]: https://www.gnu.org/software/make/manual/html_node/Overriding.html#Overriding

{% capture cmd1 %}
make test test_var='Variable ${reference}'
{% endcapture %}
{% capture out1 %}
Makefile:16: warning: undefined variable 'reference'
make: warning: undefined variable 'reference'
Variable
Variable
{% endcapture %}

{% include jekyll-theme/shell.html cmd=cmd1 out=out1 %}

This is because `make` ignores all assignments to `test_var` if it's overridden
on the command line (including `test_var := $(value test_var)`).

This can be fixed using the `override` directive for these cases only.
A complete solution that works for seemingly all cases looks like something
along these lines:

```
ifeq ($(origin test_var),environment)
    test_var := $(value test_var)
endif
ifeq ($(origin test_var),environment override)
    test_var := $(value test_var)
endif
ifeq ($(origin test_var),command line)
    override test_var := $(value test_var)
endif
```

Here, we check where the value of `test_var` comes from using the `origin`
function.
If it was defined in the environment (the `environment` and `environment
override` cases), its value is prevented from being expanded using the `value`
function.
If it was overridden on the command line (the `command line` case), the
`override` directive is used so that the unexpanded value actually gets
assigned.

The snippet above can be generalized by defining a custom function that
produces the required `make` code, and then calling `eval`.

```
define noexpand
ifeq ($$(origin $(1)),environment)
    $(1) := $$(value $(1))
endif
ifeq ($$(origin $(1)),environment override)
    $(1) := $$(value $(1))
endif
ifeq ($$(origin $(1)),command line)
    override $(1) := $$(value $(1))
endif
endef

test_var ?= This is safe.

$(eval $(call noexpand,test_var))
```

I couldn't find a case where the combination of `escape` and `noexpand`
wouldn't work.
You can even safely use other variable as the default value of `test_var`, and
it works:

{% capture out1 %}
# Prologue goes here...

escape = $(subst ','\'',$(1))

define noexpand
ifeq ($$(origin $(1)),environment)
    $(1) := $$(value $(1))
endif
ifeq ($$(origin $(1)),environment override)
    $(1) := $$(value $(1))
endif
ifeq ($$(origin $(1)),command line)
    override $(1) := $$(value $(1))
endif
endef

simple_var := Simple value

test_var ?= $(simple_var) in test_var
$(eval $(call noexpand,test_var))

simple_var := New simple value
composite_var := Composite value - $(simple_var) - $(test_var)

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(test_var))'
	@printf '%s\n' '$(call escape,$(composite_var))'
{% endcapture %}

{% capture out2 %}
New simple value in test_var
Composite value - New simple value - New simple value in test_var
{% endcapture %}

{% capture cmd3 %}
make test test_var='Variable ${reference}'
{% endcapture %}
{% capture out3 %}
Variable ${reference}
Composite value - New simple value - Variable ${reference}
{% endcapture %}

{% capture cmd4 %}
test_var='Variable ${reference}' make test
{% endcapture %}
{% capture out4 %}
Variable ${reference}
Composite value - New simple value - Variable ${reference}
{% endcapture %}

{% include jekyll-theme/shell.html cmd='cat Makefile' out=out1 %}
{% include jekyll-theme/shell.html cmd='make test' out=out2 %}
{% include jekyll-theme/shell.html cmd=cmd3 out=out3 %}
{% include jekyll-theme/shell.html cmd=cmd4 out=out4 %}
