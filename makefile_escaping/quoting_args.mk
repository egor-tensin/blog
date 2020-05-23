test_var := Same line?
export test_var

test:
	printf '%s\n' $(test_var)
	printf '%s\n' '$(test_var)'
	printf '%s\n' $$test_var
	printf '%s\n' "$$test_var"
