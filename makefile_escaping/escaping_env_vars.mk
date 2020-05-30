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

simple_var := Simple value

test_var ?= $(simple_var) in test_var
$(eval $(call escape_arg,test_var))

simple_var := New simple value
composite_var := Composite value - $(simple_var) - $(test_var)

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(test_var))'
	@printf '%s\n' '$(call escape,$(composite_var))'
