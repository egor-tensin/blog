MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c

test_var := Same line?
export test_var

test:
	printf '%s\n' $(test_var)
	printf '%s\n' '$(test_var)'
	printf '%s\n' $$test_var
	printf '%s\n' "$$test_var"
