#include <stdio.h>
#include <stdint.h>
#include <string.h>

typedef struct {
    uint16_t bits;
} bf16_t;

static inline bf16_t f32_to_bf16(float val)
{
    uint32_t f32bits;
    memcpy(&f32bits, &val, sizeof(float));
    if (((f32bits >> 23) & 0xFF) == 0xFF)
        return (bf16_t){.bits = (f32bits >> 16) & 0xFFFF};
    f32bits += ((f32bits >> 16) & 1) + 0x7FFF;
    return (bf16_t){.bits = f32bits >> 16};
}

static inline float bf16_to_f32(bf16_t val)
{
    uint32_t f32bits = ((uint32_t)val.bits) << 16;
    float result;
    memcpy(&result, &f32bits, sizeof(float));
    return result;
}

#ifndef BFLOAT16_NO_MAIN
int main(void)
{
    float test_values[] = {
        1.0f, 2.0f, 1.0f
    };

    for (size_t i = 0; i < sizeof(test_values) / sizeof(test_values[0]); i++) {
        float input = test_values[i];
        uint32_t f32bits;
        memcpy(&f32bits, &input, sizeof(float));

        // f32 -> bf16
        bf16_t bf = f32_to_bf16(input);

        // bf16 -> f32
        float back_f32 = bf16_to_f32(bf);
        uint32_t back_f32_bits;
        memcpy(&back_f32_bits, &back_f32, sizeof(float));

        printf("Test %zu:\n", i);
        printf("  Float32: %f\n", input);
        printf("  Float32 bits: 0x%08X\n", f32bits);
        printf("  BFloat16 bits: 0x%04X\n", bf.bits);
        printf("  BF16 -> Float32: %f\n", back_f32);
        printf("  BF16 -> Float32 bits: 0x%08X\n", back_f32_bits);
        printf("\n");
    }

    return 0;
}
#endif