#include "proxy.hpp"
#include "shared.hpp"

#include <iostream>

int main() {
    std::cout << shared() << '\n';
    std::cout << proxy() << '\n';
    return 0;
}
