#pragma once

inline int shared() {
    static int n = 0;
    return ++n;
}
