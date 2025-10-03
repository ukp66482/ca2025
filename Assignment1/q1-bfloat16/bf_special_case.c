#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct {
    uint16_t bits;
} bf16_t;

#define BF16_EXP_MASK  0x7F80U
#define BF16_MANT_MASK 0x007FU
#define BF16_ALL_MASK  0x7FFFU

static inline bool bf16_isnan(bf16_t a) {
    return ((a.bits & BF16_EXP_MASK) == BF16_EXP_MASK) &&
           (a.bits & BF16_MANT_MASK);
}

static inline bool bf16_isinf(bf16_t a) {
    return ((a.bits & BF16_EXP_MASK) == BF16_EXP_MASK) &&
           !(a.bits & BF16_MANT_MASK);
}

static inline bool bf16_iszero(bf16_t a) {
    return !(a.bits & BF16_ALL_MASK);
}

int main(void) {
    bf16_t specialValues[] = {
        {0x7F80}, // +Inf
        {0xFF80}, // -Inf
        {0x7FC0}, // NaN
        {0x0000}, // +0
        {0x8000}  // -0
    };

    const char *names[] = {"+Inf", "-Inf", "NaN", "+0", "-0"};

    printf("Value   | isnan | isinf | iszero\n");
    printf("---------------------------------\n");

    for (int i = 0; i < 5; i++) {
        printf("0x%04X %-4s |   %d   |   %d   |   %d\n",
               specialValues[i].bits, names[i],
               bf16_isnan(specialValues[i]),
               bf16_isinf(specialValues[i]),
               bf16_iszero(specialValues[i]));
    }

    return 0;
}