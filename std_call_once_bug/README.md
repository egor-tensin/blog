std::call_once bug in Visual C++ 2012/2013
==========================================

Code samples from the post "std::call_once bug in Visual C++ 2012/2013".

Building
--------

Create the build files using CMake and build using your native build tools
(Visual Studio/make/etc.).

In the example below, the project directory is
"C:\workspace\personal\cpp-notes" and Visual Studio 2013 is used, targeting
x86.

    > cmake -G "Visual Studio 12 2013" C:\workspace\personal\cpp-notes\std_call_once_bug
    ...

    > cmake --build . --config release
    ...

See also
--------

* [License]

[License]: ../README.md#license
