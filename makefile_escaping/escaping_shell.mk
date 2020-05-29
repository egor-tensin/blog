MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c

escape = $(subst ','\'',$(1))

cwd := $(shell basename -- "$$( pwd )")
export cwd

inner_var := Inner variable
outer_var := Outer variable - $(inner_var) - $(cwd)

echo_cwd := printf '%s\n' '$(call escape,$(cwd))'
bash_cwd := bash -c '$(call escape,$(echo_cwd))'

echo_outer_var := printf '%s\n' '$(call escape,$(outer_var))'

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(cwd))'
	@printf '%s\n' "$$cwd"
	@bash -c '$(call escape,$(echo_cwd))'
	@bash -c '$(call escape,$(bash_cwd))'
	@printf '%s\n' '$(call escape,$(outer_var))'
	@bash -c '$(call escape,$(echo_outer_var))'
