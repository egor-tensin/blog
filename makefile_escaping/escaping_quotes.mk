MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c

escape = $(subst ','\'',$(1))

test_var := Includes ' quote

echo_test_var := printf '%s\n' '$(call escape,$(test_var))'
bash_test_var := bash -c '$(call escape,$(echo_test_var))'

test:
	printf '%s\n' '$(call escape,$(test_var))'
	bash -c '$(call escape,$(echo_test_var))'
	bash -c '$(call escape,$(bash_test_var))'
