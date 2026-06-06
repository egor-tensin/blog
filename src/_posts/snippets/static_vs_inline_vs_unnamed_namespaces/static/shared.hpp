#pragma once

static int shared() {
    static int n = 0;
    return ++n;
}
