escape = $(subst ','\'',$(1))
escape_var = $(call escape,$(value $(1)))

test_var ?= This is safe.
export test_var

echo_test_var := printf '%s\n' '$(call escape_var,test_var)'
bash_test_var := bash -c '$(call escape_var,echo_test_var)'

.PHONY: test
test:
	@printf '%s\n' '$(call escape_var,test_var)'
	@printf '%s\n' "$$test_var"
	@bash -c '$(call escape_var,echo_test_var)'
	@bash -c '$(call escape_var,bash_test_var)'
