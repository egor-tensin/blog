MAKEFLAGS += --no-builtin-rules --no-builtin-variables --warn-undefined-variables
unexport MAKEFLAGS
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

escape = $(subst ','\'',$(1))

cwd := $(shell basename -- "$$( pwd )")

simple_var := Simple value
composite_var := Composite value - $(simple_var) - $(cwd)

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(cwd))'
	@printf '%s\n' '$(call escape,$(composite_var))'
