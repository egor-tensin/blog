#include "another.hpp"

#include <iostream>

namespace {

struct Test {
    Test() {
        std::cout << "main.cpp: Test::Test()\n";
    }

    int x = 1;
};

}

int main() {
    Test test;
    std::cout << test.x << '\n';
    another();
    return 0;
}
