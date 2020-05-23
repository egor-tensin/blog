escape = $(subst ','\'',$(1))

cwd := $(shell basename -- "$$( pwd )")
export cwd

echo_cwd := printf '%s\n' '$(call escape,$(cwd))'
bash_cwd := bash -c '$(call escape,$(echo_cwd))'

.PHONY: test
test:
	@printf '%s\n' '$(call escape,$(cwd))'
	@printf '%s\n' "$$cwd"
	@bash -c '$(call escape,$(echo_cwd))'
	@bash -c '$(call escape,$(bash_cwd))'
