MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c

escape = $(subst ','\'',$(1))

test_var ?= This is safe.
test_var := $(value test_var)
export test_var

# printf $test_var
echo_test_var := printf '%s\n' '$(call escape,$(test_var))'
# bash -c 'printf $test_var'
bash_test_var := bash -c '$(call escape,$(echo_test_var))'

# Simple variable.
inner_var := Inner variable
# Composite variable, includes both $inner_var and $test_var.
outer_var := Outer variable - $(inner_var) - $(test_var)

# printf $outer_var
echo_outer_var := printf '%s\n' '$(call escape,$(outer_var))'

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(test_var))'
	@printf '%s\n' "$$test_var"
	@bash -c '$(call escape,$(echo_test_var))'
	@bash -c '$(call escape,$(bash_test_var))'
	@printf '%s\n' '$(call escape,$(outer_var))'
	@bash -c '$(call escape,$(echo_outer_var))'
