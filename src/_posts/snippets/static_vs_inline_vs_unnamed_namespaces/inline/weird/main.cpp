#include "another.hpp"

#include <iostream>

inline void shared() {
    std::cout << "main.cpp: shared()\n";
}

int main() {
    shared();
    another();
    return 0;
}
