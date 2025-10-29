#ifndef HANOI_SUFFIX
#define HANOI_SUFFIX _default
#endif
#define CONCAT2(x, y) x##y
#define CONCAT(x, y) CONCAT2(x, y)

#include <stdint.h>

uint32_t CONCAT(hanoi_rec, HANOI_SUFFIX)(uint32_t n, int from, int to, int aux) {
    if (n == 0)
        return 0;

    uint32_t moves_before = CONCAT(hanoi_rec, HANOI_SUFFIX)(n - 1, from, aux, to);
    uint32_t moves_after  = CONCAT(hanoi_rec, HANOI_SUFFIX)(n - 1, aux, to, from);

    return moves_before + 1 + moves_after;
}

uint32_t CONCAT(hanoi_rec_wrapper, HANOI_SUFFIX)(uint32_t n) {
    return CONCAT(hanoi_rec, HANOI_SUFFIX)(n, 1, 3, 2);
}