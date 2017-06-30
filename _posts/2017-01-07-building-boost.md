---
title: Building Boost on Windows
layout: post
excerpt: >
  This post describes the process of building Boost on Windows using either
  Visual Studio or the combination of Cygwin + MinGW-w64.
custom_css:
  - syntax.css
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
Windows' command prompts are denoted with `>`s at the beginning of each line;
Cygwin's &mdash; with `$`s.

Visual Studio
-------------

Statically-linked Boost libraries are built, both the debug and the release
versions of them (these are default settings).
While it is required to keep x86 and x64 libraries in different directories (to
avoid file name clashes), it's not necessary to separate debug libraries from
their release counterparts, because that information is actually encoded in
file names (the "gd" suffix).

### x86

```
> cd
D:\workspace\third-party\boost_1_61_0\msvc

> bootstrap
...

> b2 --stagedir=stage\x86  ^
    runtime-link=static    ^
    --with-filesystem      ^
    --with-program_options ^
    ...
...
```

### x64

The only important difference is that you have to pass `address-model=64` to
`b2` (notice also the different "staging" directory).

```
> cd
D:\workspace\third-party\boost_1_61_0\msvc

> bootstrap
...

> b2 --stagedir=stage\x64  ^
    runtime-link=static    ^
    address-model=64       ^
    --with-filesystem      ^
    --with-program_options ^
    ...
...
```

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

```
$ pwd
/cygdrive/d/workspace/third-party/boost_1_61_0/mingw

$ ./bootstrap.sh
...

$ cat user-config-x86.jam
using gcc : : i686-w64-mingw32-g++ ;

$ ./b2 toolset=gcc-mingw              \
    target-os=windows                 \
    link=static                       \
    variant=debug                     \
    --stagedir=stage/x86/debug        \
    --user-config=user-config-x86.jam \
    --with-filesystem                 \
    --with-program_options            \
    ...
...
```

### x64

Notice the two major differences from the x86 example:

* the addition of `address-model=64` (as in the example for Visual Studio),
* the different "user" configuration file, pointing to `x86_64-w64-mingw32-g++`
instead of `i686-w64-mingw32-g++`.

Again, as in the example for Visual Studio, a different "staging" directory
needs to be specified using the `--stagedir` parameter.

```
$ cd
/cygdrive/d/workspace/third-party/boost_1_61_0/mingw

$ ./bootstrap.sh
...

$ cat user-config-x64.jam
using gcc : : x86_64-w64-mingw32-g++ ;

$ ./b2 toolset=gcc-mingw              \
    address-model=64                  \
    target-os=windows                 \
    link=static                       \
    variant=debug                     \
    --stagedir=stage/x64/debug        \
    --user-config=user-config-x64.jam \
    --with-filesystem                 \
    --with-program_options            \
    ...
...
```

Usage in CMake
--------------

### Visual Studio

Examples below apply to Visual Studio 2015.
You may want to adjust the paths.

#### x86

```
> cd
D:\workspace\build\test_project\msvc\x64

> cmake -G "Visual Studio 14 2015" ^
    -D BOOST_ROOT=D:\workspace\third-party\boost_1_61_0\msvc                     ^
    -D BOOST_LIBRARYDIR=D:\workspace\third-party\boost_1_61_0\msvc\stage\x86\lib ^
    -D Boost_USE_STATIC_LIBS=ON    ^
    -D Boost_USE_STATIC_RUNTIME=ON ^
    ...
```

#### x64

```
> cd
D:\workspace\build\test_project\msvc\x86

> cmake -G "Visual Studio 14 2015 Win64" ^
    -D BOOST_ROOT=D:\workspace\third-party\boost_1_61_0\msvc                     ^
    -D BOOST_LIBRARYDIR=D:\workspace\third-party\boost_1_61_0\msvc\stage\x64\lib ^
    -D Boost_USE_STATIC_LIBS=ON          ^
    -D Boost_USE_STATIC_RUNTIME=ON       ^
    ...
```

### Cygwin & MinGW-w64

Examples below only apply to debug CMake builds.
Notice that, contrary to the Visual Studio examples above, debug and release
builds must be kept in separate directories.
You may also want to adjust the paths.

#### x86

```
$ pwd
/cygdrive/d/workspace/build/test_project/mingw/x86/debug

$ cmake -G "Unix Makefiles"                    \
    -D CMAKE_BUILD_TYPE=Debug                  \
    -D CMAKE_C_COMPILER=i686-w64-mingw32-gcc   \
    -D CMAKE_CXX_COMPILER=i686-w64-mingw32-g++ \
    -D BOOST_ROOT=/cygdrive/d/workspace/third-party/boost_1_61_0/mingw                     \
    -D BOOST_LIBRARYDIR=/cygdrive/d/workspace/third-party/boost_1_61_0/mingw/x86/debug/lib \
    -D Boost_USE_STATIC_LIBS=ON                \
    ...
```

#### x64

```
$ pwd
/cygdrive/d/workspace/build/test_project/mingw/x64/debug

$ cmake -G "Unix Makefiles"                      \
    -D CMAKE_BUILD_TYPE=Debug                    \
    -D CMAKE_C_COMPILER=x86_64-w64-mingw32-gcc   \
    -D CMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -D BOOST_ROOT=/cygdrive/d/workspace/third-party/boost_1_61_0/mingw                     \
    -D BOOST_LIBRARYDIR=/cygdrive/d/workspace/third-party/boost_1_61_0/mingw/x64/debug/lib \
    -D Boost_USE_STATIC_LIBS=ON                  \
    ...
```
