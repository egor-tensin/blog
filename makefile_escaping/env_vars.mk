escape = $(subst ','\'',$(1))

test_var ?= This is safe.
test_var := $(value test_var)
export test_var

inner_var := Inner variable
outer_var := Outer variable - $(inner_var) - $(test_var)

echo_test_var := printf '%s\n' '$(call escape,$(test_var))'
bash_test_var := bash -c '$(call escape,$(echo_test_var))'

echo_outer_var := printf '%s\n' '$(call escape,$(outer_var))'

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(test_var))'
	@printf '%s\n' "$$test_var"
	@bash -c '$(call escape,$(echo_test_var))'
	@bash -c '$(call escape,$(bash_test_var))'
	@printf '%s\n' '$(call escape,$(outer_var))'
	@bash -c '$(call escape,$(echo_outer_var))'
