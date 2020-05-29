MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c

escape = $(subst ','\'',$(1))

cwd := $(shell basename -- "$$( pwd )")
export cwd

# printf $cwd
echo_cwd := printf '%s\n' '$(call escape,$(cwd))'
# bash -c 'printf $cwd'
bash_cwd := bash -c '$(call escape,$(echo_cwd))'

# Simple variable.
inner_var := Inner variable
# Composite variable, includes both $inner_var and $cwd.
outer_var := Outer variable - $(inner_var) - $(cwd)

# printf $outer_var
echo_outer_var := printf '%s\n' '$(call escape,$(outer_var))'

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(cwd))'
	@printf '%s\n' "$$cwd"
	@bash -c '$(call escape,$(echo_cwd))'
	@bash -c '$(call escape,$(bash_cwd))'
	@printf '%s\n' '$(call escape,$(outer_var))'
	@bash -c '$(call escape,$(echo_outer_var))'
