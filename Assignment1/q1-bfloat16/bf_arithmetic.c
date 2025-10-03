#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

typedef struct {
    uint16_t bits;
} bf16_t;

static inline bf16_t f32_to_bf16(float val) {
    uint32_t f32bits;
    memcpy(&f32bits, &val, sizeof(float));
    if (((f32bits >> 23) & 0xFF) == 0xFF)
        return (bf16_t){.bits = (f32bits >> 16) & 0xFFFF};
    f32bits += ((f32bits >> 16) & 1) + 0x7FFF;
    return (bf16_t){.bits = f32bits >> 16};
}

static inline float bf16_to_f32(bf16_t val) {
    uint32_t f32bits = ((uint32_t)val.bits) << 16;
    float result;
    memcpy(&result, &f32bits, sizeof(float));
    return result;
}

#define WRAP_BINOP(name, op) \
    static inline bf16_t bf16_##name(bf16_t a, bf16_t b) { \
        float fa = bf16_to_f32(a); \
        float fb = bf16_to_f32(b); \
        float fres = fa op fb; \
        return f32_to_bf16(fres); \
    }

WRAP_BINOP(add, +)
WRAP_BINOP(sub, -)
WRAP_BINOP(mul, *)
WRAP_BINOP(div, /)

static inline bf16_t bf16_sqrt(bf16_t a) {
    return f32_to_bf16(sqrtf(bf16_to_f32(a)));
}

// 輔助函數：印出 float 的 16進位
static inline uint32_t float_to_hex(float val) {
    uint32_t bits;
    memcpy(&bits, &val, sizeof(bits));
    return bits;
}

// 印出二元運算的 input/output
static void print_binop(const char *expr, float fa, float fb, float fres) {
    printf("%s\n", expr);
    printf("  input a = %.6f  (FP32 hex=0x%08X)\n", fa, float_to_hex(fa));
    printf("  input b = %.6f  (FP32 hex=0x%08X)\n", fb, float_to_hex(fb));
    printf("  result  = %.6f  (FP32 hex=0x%08X)\n\n", fres, float_to_hex(fres));
}

// 印出單元運算 (sqrt)
static void print_unop(const char *expr, float fa, float fres) {
    printf("%s\n", expr);
    printf("  input  = %.6f  (FP32 hex=0x%08X)\n", fa, float_to_hex(fa));
    printf("  result = %.6f  (FP32 hex=0x%08X)\n\n", fres, float_to_hex(fres));
}

int main(void) {
    bf16_t a, b, c;
    float fa, fb, fres;

    printf("Arithmetic with FP32 input/output hex representation:\n\n");

    // Addition
    fa = 1.0f; fb = 2.0f;
    a = f32_to_bf16(fa); b = f32_to_bf16(fb);
    c = bf16_add(a, b); fres = bf16_to_f32(c);
    print_binop("1.0 + 2.0", fa, fb, fres);

    // Subtraction
    fa = 2.0f; fb = 1.0f;
    a = f32_to_bf16(fa); b = f32_to_bf16(fb);
    c = bf16_sub(a, b); fres = bf16_to_f32(c);
    print_binop("2.0 - 1.0", fa, fb, fres);

    // Multiplication
    fa = 3.0f; fb = 4.0f;
    a = f32_to_bf16(fa); b = f32_to_bf16(fb);
    c = bf16_mul(a, b); fres = bf16_to_f32(c);
    print_binop("3.0 * 4.0", fa, fb, fres);

    // Division
    fa = 10.0f; fb = 2.0f;
    a = f32_to_bf16(fa); b = f32_to_bf16(fb);
    c = bf16_div(a, b); fres = bf16_to_f32(c);
    print_binop("10.0 / 2.0", fa, fb, fres);

    // Square root 4
    fa = 4.0f;
    a = f32_to_bf16(fa);
    c = bf16_sqrt(a); fres = bf16_to_f32(c);
    print_unop("sqrt(4.0)", fa, fres);

    // Square root 9
    fa = 9.0f;
    a = f32_to_bf16(fa);
    c = bf16_sqrt(a); fres = bf16_to_f32(c);
    print_unop("sqrt(9.0)", fa, fres);

    return 0;
}