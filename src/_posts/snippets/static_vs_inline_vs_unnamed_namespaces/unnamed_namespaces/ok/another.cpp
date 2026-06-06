#include "another.hpp"

#include <iostream>

namespace {

struct Test {
    Test() {
        std::cout << "another.cpp: Test::Test()\n";
    }

    float y = 1.;
};

}

void another() {
    Test test;
}
