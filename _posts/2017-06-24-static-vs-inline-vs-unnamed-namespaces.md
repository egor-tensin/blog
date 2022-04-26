---
title: static vs. inline vs. namespace&nbsp;{
excerpt: >
  Should I use `static`, `inline` or unnamed namespaces for function
  definitions?
category: C++
snippets_root_directory: snippets/static_vs_inline_vs_unnamed_namespaces
snippets_language: c++
snippets:
  static:
    - static/main.cpp
    - static/proxy.cpp
    - static/proxy.hpp
    - static/shared.hpp
  inline:
    - inline/shared.hpp
  inline_weird:
    - inline/weird/main.cpp
    - inline/weird/another.cpp
    - inline/weird/another.hpp
  unnamed_namespaces_weird:
    - unnamed_namespaces/weird/main.cpp
    - unnamed_namespaces/weird/another.cpp
    - unnamed_namespaces/weird/another.hpp
  unnamed_namespaces_ok:
    - unnamed_namespaces/ok/main.cpp
    - unnamed_namespaces/ok/another.cpp
    - unnamed_namespaces/ok/another.hpp
  static_and_inline:
    - static_and_inline/main.cpp
    - static_and_inline/proxy.cpp
    - static_and_inline/proxy.hpp
    - static_and_inline/shared.hpp
  unnamed_namespace_and_inline:
    - unnamed_namespace_and_inline/main.cpp
    - unnamed_namespace_and_inline/proxy.cpp
    - unnamed_namespace_and_inline/proxy.hpp
    - unnamed_namespace_and_inline/shared.hpp
  separate_method_definitions:
    - separate_method_definitions/main.cpp
    - separate_method_definitions/another.cpp
    - separate_method_definitions/another.hpp
    - separate_method_definitions/shared.hpp
---
In this post I'll try to figure out whether I should use `static`, `inline` or
unnamed namespaces for function definitions.

TL;DR
-----

Here's my attempt to build an algorithm to decide whether a class/function
should be defined with either of the `static`/`inline` specifiers or put into
an unnamed namespace.
The first question I answer is: is the entity defined in a header file or in a
.cpp file?

* **In a header** &mdash; Is it a class or a function?
    * **Class** &mdash; There's no need to do anything.
    * **Function** &mdash; Do you want it to behave differently for each
translation unit (may be useful, for example, for logging)?
        * **Yes** &mdash; Use `static`.
        * **No** &mdash; Use `inline`.
* **In a .cpp file** &mdash; Put it into an unnamed namespace.

`static`
--------

It's an old C-style method of defining functions in header files.
This way, every translation unit gets its own copy of a function.
What does that mean?
The most obvious implication that pops into my head is that every local static
variable defined inside that function gets an independent replica in every
translation unit.
For example, the program below would print

```
1
1
```

due to the fact that both main.cpp and proxy.cpp get their own versions of `n`
from `shared()`.

{% include jekyll-theme/snippets/section.html section_id='static' %}

In C, this is the only way to share function definitions between translation
units (apart from the usual way of declaring a function in a header file and
putting its definition to a .c file).

### Properties

* Using `static`, you can share function definitions between multiple
translation units.
* Each unit gets its own replica of the function: they have different
addresses, their local static variables are independent, etc.
* If different translation units define different functions with the same
name using the `static` specifier, each unit can use its function without any
issues.
This might seem like an trivial claim, but other approaches sometimes disallow
this, which is discussed below.

`inline`
--------

It's well-known that this keyword has pretty much nothing to do with whether a
function will actually be inlined or not.
It's used much more often to define functions in header files, since every
function defined this way will be the same (as in "will have the same address")
in every translation unit.
Let's try and adjust the definition of `shared()` accordingly:

{% include jekyll-theme/snippets/section.html section_id='inline' %}

The same program would then print

```
1
2
```

since both `main()` and `proxy()` would call the same `shared()`, incrementing
the same `n`.

Weird things happen when different translation units define different `inline`
functions with the same name.

{% include jekyll-theme/snippets/section.html section_id='inline_weird' %}

According to my simple experiments, this program produces different output
based on which .cpp file was specified first on the command line during
compilation.
For example, this is the output of test.exe produced with either `cl /W4 /EHsc
main.cpp another.cpp /Fe:test.exe` or `g++ -Wall -Wextra -std=c++11 main.cpp
another.cpp -o test.exe`.

```
main.cpp: shared()
main.cpp: shared()
```

If we swap the order of .cpp files (`another.cpp main.cpp` instead of `main.cpp
another.cpp`), the output becomes

```
another.cpp: shared()
another.cpp: shared()
```

No warnings/errors are emitted, making the situation truly disturbing.
I tested this with GNU compiler version 5.4.0 and Microsoft compiler version
19.00.24210.

This behavior can be easily fixed either by making these functions `static` or
by using unnamed namespaces (see below).

### Properties

* Using `inline`, you can share function definitions between multiple
translation units.
* Each translation unit will use the same function: it will have the same
address in every translation unit, its local static variables will be shared,
etc.
* Defining different `inline` functions with the same name in different
translation units is undefined behavior.

Two inline functions might be different even if they are the same textually.
For example, they might reference two global variables which have the same
name, but are defined in different translation units.
{: .alert .alert-info }

`namespace {`
-------------

With respect to function definitions, unnamed namespaces are, according to my
understanding, quite similar to the `static` keyword.
The additional value they provide is that they provide a way to apply `static`
not only to functions, but to classes also.
Remember the weirdness that happens when multiple translation units define
different `inline` functions with the same name?
Arguably, it gets even worse if we add classes to the equation.

{% include jekyll-theme/snippets/section.html section_id='unnamed_namespaces_weird' %}

Compiling this program the same way we did in the `inline` example (`cl /W4
/EHsc main.cpp another.cpp /Fe:test.exe`/`g++ -Wall -Wextra -std=c++11 main.cpp
another.cpp -o test.exe`) yields different outputs depending on which .cpp file
was specified first.

```
main.cpp: Test::Test()
1
main.cpp: Test::Test()
```

```
another.cpp: Test::Test()
1065353216
another.cpp: Test::Test()
```

I'm not sure why anybody would want that.
This can be easily fixed by putting both `Test` classes into unnamed
namespaces.
The program than reads

{% include jekyll-theme/snippets/section.html section_id='unnamed_namespaces_ok' %}

After the adjustment, it produces the same output regardless of compilation
options.

```
main.cpp: Test::Test()
1
another.cpp: Test::Test()
```

Notice how sharing classes defined in header files isn't discussed here.
The standard actually guarantees that if a class is defined in a header file,
all translation units that use it share the definition.

### Properties

* Essentially, unnamed namespaces allow the `static` keyword to be applied to
classes.
* Similar to the `static` approach, each translation unit gets its own replica
of a function/class, including their own local static variables, etc.
* Defining different classes with the same name in different translation units
(without utilizing unnamed namespaces) is undefined behavior.

Tricky cases
------------

### `static` + `inline`

In case a function is defined as `static inline`, `static` wins, and `inline`
is ignored.
The program below outputs

```
1
1
```

{% include jekyll-theme/snippets/section.html section_id='static_and_inline' %}

In general, I can't think of a reason to define a `static inline` function.

### `namespace {` + `inline`

If an `inline` function is defined in an unnamed namespace, the unnamed
namespace wins.
The program below outputs

```
1
1
```

{% include jekyll-theme/snippets/section.html section_id='unnamed_namespace_and_inline' %}

In general, I can't think of a reason to define an `inline` function in an
unnamed namespace.

### Separate method definitions

If you want to separate your class declaration from its method definitions
while keeping them in the same header file, each method must be explicitly
defined `inline`.
The program below outputs

```
1
2
```

{% include jekyll-theme/snippets/section.html section_id='separate_method_definitions' %}
