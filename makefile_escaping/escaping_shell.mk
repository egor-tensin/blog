MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c

escape = $(subst ','\'',$(1))

cwd := $(shell basename -- "$$( pwd )")

echo_cwd := printf '%s\n' '$(call escape,$(cwd))'
bash_cwd := bash -c '$(call escape,$(echo_cwd))'

simple_var := Simple value
compisite_var := Composite value - $(simple_var) - $(cwd)

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(cwd))'
	@printf '%s\n' '$(call escape,$(compisite_var))'
