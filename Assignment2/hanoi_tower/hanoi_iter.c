#ifndef HANOI_SUFFIX
#define HANOI_SUFFIX _default
#endif
#define CONCAT2(x, y) x##y
#define CONCAT(x, y) CONCAT2(x, y)

#include <stdint.h>

uint32_t CONCAT(hanoi_iter, HANOI_SUFFIX)(uint32_t n) {
    if (n == 0)
        return 0;

    uint32_t total_moves = (1u << n) - 1; // 2^n - 1 moves total
    uint32_t count = 0;
    volatile uint32_t gray_now, gray_prev, diff;
    // Gray code iteration:
    for (uint32_t i = 1; i <= total_moves; i++) {
        // gray(i) = i ^ (i >> 1)
        gray_now = i ^ (i >> 1);
        gray_prev = (i - 1) ^ ((i - 1) >> 1);
        // which disk moves -> bit position that changed
        diff = gray_now ^ gray_prev;
        count++;
    }

    return count;
}