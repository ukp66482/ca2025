#include <stdio.h>
#include <stdint.h>

/*-------------------------------------------------
  Optimized version using builtin bit operations
  (CLZ + POPCOUNT)
  NOTE: Use unsigned 32-bit to correctly handle 0xFFFFFFFF.
-------------------------------------------------*/
int numberOfSteps_fast(uint32_t num) {
    if (num == 0u) return 0;

    // __builtin_clz / __builtin_popcount take unsigned int; cast explicitly.
    int bits = 32 - __builtin_clz((unsigned int)num);   // 32 - leading zeros
    int ones = __builtin_popcount((unsigned int)num);   // count of 1 bits

    return (bits - 1) + ones;
}

/*-------------------------------------------------
  Simple version using direct while-loop
  (no bit tricks).  Use unsigned ops to avoid
  negative arithmetic when num = 0xFFFFFFFF.
-------------------------------------------------*/
int numberOfSteps_simple(uint32_t num) {
    int steps = 0;
    while (num != 0u) {
        if ((num & 1u) == 0u) {
            num >>= 1;       // even: divide by 2
        } else {
            num -= 1u;       // odd: subtract 1
        }
        steps++;
    }
    return steps;
}

/*-------------------------------------------------
  Test harness
-------------------------------------------------*/
int main(void) {

    uint32_t tests[20] = {
        0u, 1u, 2u, 3u, 4u,
        7u, 8u, 14u, 15u, 16u,
        31u, 32u, 63u, 64u, 123u,
        255u, 256u, 1023u, 1024u, 0xFFFFFFFFu
    };

    int expected[20] = {
        0, 1, 2, 3, 3,
        5, 4, 6, 7, 5,
        9, 6, 11, 7, 12,
        15, 9, 19, 11, 63
    };

    printf("=== Optimized (CLZ + POPCOUNT) version ===\n");
    for (int i = 0; i < 20; i++) {
        int result = numberOfSteps_fast(tests[i]);
        printf("Test %2d: num=%10u -> steps=%2d (expected %2d)%s\n",
               i + 1, tests[i], result, expected[i],
               (result == expected[i]) ? " OK" : " Failed");
    }

    printf("\n=== Simple loop version ===\n");
    for (int i = 0; i < 20; i++) {
        int result = numberOfSteps_simple(tests[i]);
        printf("Test %2d: num=%10u -> steps=%2d (expected %2d)%s\n",
               i + 1, tests[i], result, expected[i],
               (result == expected[i]) ? " OK" : " Failed");
    }

    return 0;
}