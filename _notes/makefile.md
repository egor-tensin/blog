---
title: GNU Make
---
Best practices for my Makefiles (sorry for the botched highlighting).

```make
# Put this in the top of the Makefile:

MAKEFLAGS += --no-builtin-rules --no-builtin-variables --warn-undefined-variables
unexport MAKEFLAGS
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

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

# OK, now some examples of how to use it:

.PHONY: all
all: test-escape test-noexpand

# Always put command arguments in single quotes.
# Escape variables and shell output using the escape function.

var_with_quote := Includes ' quote

.PHONY: test-escape
test-escape:
	printf '%s\n' '$(call escape,$(var_with_quote))'
	printf '%s\n' '$(call escape,$(shell echo "Includes ' quote"))'

# The above recipe will print "Includes ' quote" twice.

# If you define variables using ?= or use environment variables in your
# Makefile, use noexpand on them (to safeguard against ${accidental}
# references).

var_with_default ?= Accidental reference?
$(eval $(call noexpand,var_with_default))

$(eval $(call noexpand,env_var))

.PHONY: test-noexpand
test-noexpand:
	printf '%s\n' '$(call escape,$(var_with_default))'
	printf '%s\n' '$(call escape,$(env_var))'

# The above recipe will print "Accidental ${reference}" twice if you run using
# env_var='Accidental ${reference}' make var_with_default='Accidental ${reference}'
```
