MAKEFLAGS += --no-builtin-rules --no-builtin-variables --warn-undefined-variables
unexport MAKEFLAGS
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

test_var := Same line?
export test_var

test:
	@printf '%s\n' $(test_var)
	@printf '%s\n' '$(test_var)'
	@printf '%s\n' $$test_var
	@printf '%s\n' "$$test_var"
