#include "another.hpp"

#include <iostream>

inline void shared() {
    std::cout << "another.cpp: shared()\n";
}

void another() {
    shared();
}
