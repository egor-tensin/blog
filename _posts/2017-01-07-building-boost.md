---
title: Building Boost on Windows
excerpt: >
  This post describes the process of building Boost on Windows using either
  Visual Studio or the combination of Cygwin + MinGW-w64.
category: C++
---
Below you can find the steps required to build Boost libraries on Windows.
These steps tightly fit my typical workflow, which is to use Boost libraries in
CMake builds using either Visual Studio or the combination of Cygwin +
MinGW-w64.
I would expect, however, that the procedure for the latter toolset can easily
be adjusted for generic GCC distributions (including vanilla GCCs found in
popular Linux distributions).

One of the features of this workflow is that I build throwaway, "run
everywhere, record the results, and scrap it" executables more often than not,
so I prefer to link everything statically, including, for instance, C/C++
runtimes.
This is implemented by passing `runtime-link=static` to Boost's build utility
`b2`; change this to `runtime-link=dynamic` to link the runtime dynamically.

Excerpts from shell sessions in this post feature a few different commands
besides Boost's `b2` and `cmake`, like `cd` and `cat`.
They are used to hint at my personal directory layout, display various
auxiliary files, etc.
Windows' `cd`, for example, simply prints the current working directory;
Cygwin's `pwd` serves the same purpose.
`cat` is used to display files.

Visual Studio
-------------

Statically-linked Boost libraries are built, both the debug and the release
versions of them (these are default settings).
While it is required to keep x86 and x64 libraries in different directories (to
avoid file name clashes), it's not necessary to separate debug libraries from
their release counterparts, because that information is actually encoded in
file names (the "gd" suffix).

### x86

{% capture out1 %}
D:\workspace\third-party\boost_1_61_0\msvc
{% endcapture %}

{% capture cmd3 %}
b2 --stagedir=stage\x86    ^
    runtime-link=static    ^
    --with-filesystem      ^
    --with-program_options ^
    ...
{% endcapture %}

{% include shell.html cmd='cd' out=out1 %}
{% include shell.html cmd='bootstrap' %}
{% include shell.html cmd=cmd3 %}

### x64

The only important difference is that you have to pass `address-model=64` to
`b2` (notice also the different "staging" directory).

{% capture out1 %}
D:\workspace\third-party\boost_1_61_0\msvc
{% endcapture %}

{% capture cmd3 %}
b2 --stagedir=stage\x64    ^
    runtime-link=static    ^
    address-model=64       ^
    --with-filesystem      ^
    --with-program_options ^
    ...
{% endcapture %}

{% include shell.html cmd='cd' out=out1 %}
{% include shell.html cmd='bootstrap' %}
{% include shell.html cmd=cmd3 %}

Cygwin + MinGW-w64
------------------

Contrary to the Visual Studio example above, it is required to store debug and
release libraries *as well as* x86 and x64 libraries in different directories.
It is required to avoid file name clashes; unlike the Visual Studio "toolset"
(in Boost's terms), GCC-derived toolsets don't encode any information (like
whether the debug or the release version of a library was built) in file names.

Also, linking the runtime statically doesn't really make sense for MinGW, as it
always links to msvcrt.dll, which is [simply the Visual Studio 6.0 runtime].

[simply the Visual Studio 6.0 runtime]: https://sourceforge.net/p/mingw-w64/wiki2/The%20case%20against%20msvcrt.dll/

In the examples below, only the debug versions of the libraries are built.
Build the release versions by executing the same command, and substituting
`variant=release` instead of `variant=debug` and either
`--stagedir=stage/x86/release` or `--stagedir=stage/x64/release`, depending
on the target architecture.

### x86

{% capture out1 %}
/cygdrive/d/workspace/third-party/boost_1_61_0/mingw
{% endcapture %}

{% capture out3 %}
using gcc : : i686-w64-mingw32-g++ ;
{% endcapture %}

{% capture cmd4 %}
./b2 toolset=gcc-mingw                \
    target-os=windows                 \
    link=static                       \
    variant=debug                     \
    --stagedir=stage/x86/debug        \
    --user-config=user-config-x86.jam \
    --with-filesystem                 \
    --with-program_options            \
    ...
{% endcapture %}

{% include shell.html cmd='pwd' out=out1 %}
{% include shell.html cmd='./bootstrap.sh' %}
{% include shell.html cmd='cat user-config-x86.jam' out=out3 %}
{% include shell.html cmd=cmd4 %}

The "user" configuration file above stopped working at some point; not sure as
to who's to blame, Cygwin or Boost.
If you see something like "`error: provided command 'i686-w64-mingw32-g++' not
found`", add ".exe" to the binary name above, so that the whole file reads
"`using gcc : : i686-w64-mingw32-g++.exe ;`".
{: .alert .alert-info }

### x64

Notice the two major differences from the x86 example:

* the addition of `address-model=64` (as in the example for Visual Studio),
* the different "user" configuration file, pointing to `x86_64-w64-mingw32-g++`
instead of `i686-w64-mingw32-g++`.

Again, as in the example for Visual Studio, a different "staging" directory
needs to be specified using the `--stagedir` parameter.

{% capture out1 %}
/cygdrive/d/workspace/third-party/boost_1_61_0/mingw
{% endcapture %}

{% capture out3 %}
using gcc : : x86_64-w64-mingw32-g++ ;
{% endcapture %}

{% capture cmd4 %}
./b2 toolset=gcc-mingw                \
    address-model=64                  \
    target-os=windows                 \
    link=static                       \
    variant=debug                     \
    --stagedir=stage/x64/debug        \
    --user-config=user-config-x64.jam \
    --with-filesystem                 \
    --with-program_options            \
    ...
{% endcapture %}

{% include shell.html cmd='pwd' out=out1 %}
{% include shell.html cmd='./bootstrap.sh' %}
{% include shell.html cmd='cat user-config-x64.jam' out=out3 %}
{% include shell.html cmd=cmd4 %}

The "user" configuration file above stopped working at some point; not sure as
to who's to blame, Cygwin or Boost.
If you see something like "`error: provided command 'x86_64-w64-mingw32-g++'
not found`", add ".exe" to the binary name above, so that the whole file reads
"`using gcc : : x86_64-w64-mingw32-g++.exe ;`".
{: .alert .alert-info }

Usage in CMake
--------------

### Visual Studio

Examples below apply to Visual Studio 2015.
You may want to adjust the paths.

#### x86

{% capture out1 %}
D:\workspace\build\test_project\msvc\x86
{% endcapture %}

{% capture cmd2 %}
cmake -G "Visual Studio 14 2015" ^
    -D BOOST_ROOT=D:\workspace\third-party\boost_1_61_0\msvc ^
    -D BOOST_LIBRARYDIR=D:\workspace\third-party\boost_1_61_0\msvc\stage\x86\lib ^
    -D Boost_USE_STATIC_LIBS=ON ^
    -D Boost_USE_STATIC_RUNTIME=ON ^
    ...
{% endcapture %}

{% include shell.html cmd='cd' out=out1 %}
{% include shell.html cmd=cmd2 %}

#### x64

{% capture out1 %}
D:\workspace\build\test_project\msvc\x64
{% endcapture %}

{% capture cmd2 %}
cmake -G "Visual Studio 14 2015 Win64" ^
    -D BOOST_ROOT=D:\workspace\third-party\boost_1_61_0\msvc ^
    -D BOOST_LIBRARYDIR=D:\workspace\third-party\boost_1_61_0\msvc\stage\x64\lib ^
    -D Boost_USE_STATIC_LIBS=ON ^
    -D Boost_USE_STATIC_RUNTIME=ON ^
    ...
{% endcapture %}

{% include shell.html cmd='cd' out=out1 %}
{% include shell.html cmd=cmd2 %}

### Cygwin & MinGW-w64

Examples below only apply to debug CMake builds.
Notice that, contrary to the Visual Studio examples above, debug and release
builds must be kept in separate directories.
You may also want to adjust the paths.

#### x86

{% capture out1 %}
/cygdrive/d/workspace/build/test_project/mingw/x86/debug
{% endcapture %}

{% capture cmd2 %}
cmake -G "Unix Makefiles"                      \
    -D CMAKE_BUILD_TYPE=Debug                  \
    -D CMAKE_C_COMPILER=i686-w64-mingw32-gcc   \
    -D CMAKE_CXX_COMPILER=i686-w64-mingw32-g++ \
    -D BOOST_ROOT=/cygdrive/d/workspace/third-party/boost_1_61_0/mingw                           \
    -D BOOST_LIBRARYDIR=/cygdrive/d/workspace/third-party/boost_1_61_0/mingw/stage/x86/debug/lib \
    -D Boost_USE_STATIC_LIBS=ON                \
    ...
{% endcapture %}

{% include shell.html cmd='pwd' out=out1 %}
{% include shell.html cmd=cmd2 %}

#### x64

{% capture out1 %}
/cygdrive/d/workspace/build/test_project/mingw/x64/debug
{% endcapture %}

{% capture cmd2 %}
cmake -G "Unix Makefiles"                        \
    -D CMAKE_BUILD_TYPE=Debug                    \
    -D CMAKE_C_COMPILER=x86_64-w64-mingw32-gcc   \
    -D CMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -D BOOST_ROOT=/cygdrive/d/workspace/third-party/boost_1_61_0/mingw                           \
    -D BOOST_LIBRARYDIR=/cygdrive/d/workspace/third-party/boost_1_61_0/mingw/stage/x64/debug/lib \
    -D Boost_USE_STATIC_LIBS=ON                  \
    ...
{% endcapture %}

{% include shell.html cmd='pwd' out=out1 %}
{% include shell.html cmd=cmd2 %}
