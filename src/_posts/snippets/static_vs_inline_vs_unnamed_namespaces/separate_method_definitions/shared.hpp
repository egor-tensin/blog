#pragma once

#include <iostream>

struct Test {
    Test();
};

inline Test::Test() {
    static int x = 0;
    std::cout << ++x << '\n';
}
