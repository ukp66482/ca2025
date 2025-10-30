#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <fenv.h>

#ifndef Q
#define Q 16
#endif

#define ONE_Q16   (1ull << Q)   // 1.0 in Q16.16 (64-bit)

static inline uint64_t rsqrt_q16_16_ref_u64(uint64_t x_q16)
{
    if (x_q16 == 0) return 0xFFFFFFFFFFFFFFFFull;

    long double x = (long double)x_q16 / (long double)ONE_Q16;
    long double y = 1.0L / sqrtl(x);                        
    long double y_q = y * (long double)ONE_Q16;             
    long long r = llrintl(y_q);                              

    if (r < 0) r = 0;
    if ((unsigned long long)r > 0xFFFFFFFFFFFFFFFFull)
        r = 0xFFFFFFFFFFFFFFFFull;
    return (uint64_t)r;
}

int main(void)
{
    uint64_t test_values[] = {
        1, 2, 3, 4, 10, 16, 100, 1000, 10000,
        65536, 123456, 7890123, 100000000
    };
    int num_tests = sizeof(test_values) / sizeof(test_values[0]);

    printf("==== Reciprocal sqrt (Q16.16 integer output) ====\n\n");

    for (int i = 0; i < num_tests; i++) {
        uint64_t x = test_values[i];
        uint64_t x_q16 = x << Q;
        uint64_t y_q16 = rsqrt_q16_16_ref_u64(x_q16);

        printf("rsqrt_ref(%llu) = %llu\n",
               (unsigned long long)x,
               (unsigned long long)y_q16);
    }

    return 0;
}