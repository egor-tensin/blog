MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c

escape = $(subst ','\'',$(1))

define escape_arg
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

# Simple variable.
simple_var := Simple value

test_var ?= $(simple_var)
export test_var

$(eval $(call escape_arg,test_var))

simple_var := New simple value

# printf $test_var
echo_test_var := printf '%s\n' '$(call escape,$(test_var))'
# bash -c 'printf $test_var'
bash_test_var := bash -c '$(call escape,$(echo_test_var))'

# Composite variable, includes both $simple_var and $test_var.
composite_var := Composite value - $(simple_var) - $(test_var)

# printf $composite_var
echo_composite_var := printf '%s\n' '$(call escape,$(composite_var))'

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(test_var))'
	@printf '%s\n' "$$test_var"
	@bash -c '$(call escape,$(echo_test_var))'
	@bash -c '$(call escape,$(bash_test_var))'
	@printf '%s\n' '$(call escape,$(composite_var))'
	@bash -c '$(call escape,$(echo_composite_var))'
