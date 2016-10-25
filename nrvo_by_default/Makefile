# Builds rvo.cpp on various optimization levels supported by GCC.
# The compiler is `g++` by default.
# You can change the compiler to be used using the CXX variable.
# For example, if you want to compile using `x86_64-w64-mingw32-g++`, run
#
#     > make CXX=x86_64-w64-mingw32-g++

CXXFLAGS = -Wall -Wextra -DNDEBUG -std=c++11 -static-libgcc -static-libstdc++ -s

optimization_levels = 0 1 2 3

all::

define make_target
rvo.$(CXX).O$(1).exe: rvo.cpp
	$(CXX) $(CXXFLAGS) -O$(1) $$< -o $$@

all:: rvo.$(CXX).O$(1).exe
endef

$(foreach i,$(optimization_levels),$(eval $(call make_target,$(i))))

.PHONY: clean-all

clean-all:
	$(RM) $(wildcard rvo.$(CXX).*.exe)
