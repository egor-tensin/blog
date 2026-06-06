#pragma once

namespace {

inline int shared() {
    static int x = 0;
    return ++x;
}

}
