#pragma once

static inline int shared() {
    static int x = 0;
    return ++x;
}
