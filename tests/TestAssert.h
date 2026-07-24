#pragma once

#include <iostream>

#define CPPTEST_ASSERT(expr)                                                                                           \
    do {                                                                                                               \
        if (!(expr)) {                                                                                                 \
            std::cerr << "Test failed: " << #expr                                                                      \
                      << " | file: " << __FILE__                                                                        \
                      << " | line: " << __LINE__ << std::endl;                                                         \
            return -1;                                                                                                 \
        }                                                                                                              \
    } while (0)

#define CPPTEST_RUN(func, ...)                                                                                         \
    do {                                                                                                               \
        if ((func)(__VA_ARGS__) != 0)                                                                                  \
            return -1;                                                                                                 \
    } while (0)
