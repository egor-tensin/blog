std::call_once bug in Visual C++ 2012/2013
==========================================

The complete code sample from the post "std::call_once bug in Visual C++
2012/2013".

Building
--------

Create the build files using CMake and build using your native build tools
(Visual Studio/make/etc.).

In the example below, the project directory is "C:\workspace\personal\blog"
and Visual Studio 2013 is used.

    > cmake -G "Visual Studio 12 2013" C:\workspace\personal\blog\std_call_once_bug
    ...

    > cmake --build . --config release
    ...
