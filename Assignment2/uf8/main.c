#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#define printstr(ptr, length)                   \
    do {                                        \
        asm volatile(                           \
            "add a7, x0, 0x40;"                 \
            "add a0, x0, 0x1;" /* stdout */     \
            "add a1, x0, %0;"                   \
            "mv a2, %1;" /* length character */ \
            "ecall;"                            \
            :                                   \
            : "r"(ptr), "r"(length)             \
            : "a0", "a1", "a2", "a7");          \
    } while (0)

#define TEST_OUTPUT(msg, length) printstr(msg, length)

#define TEST_LOGGER(msg)                     \
    {                                        \
        char _msg[] = msg;                   \
        TEST_OUTPUT(_msg, sizeof(_msg) - 1); \
    }

extern uint64_t get_cycles(void);
extern uint64_t get_instret(void);

/* Bare metal memcpy implementation */
void *memcpy(void *dest, const void *src, size_t n)
{
    uint8_t *d = (uint8_t *) dest;
    const uint8_t *s = (const uint8_t *) src;
    while (n--)
        *d++ = *s++;
    return dest;
}

/* Software division for RV32I (no M extension) */
static unsigned long udiv(unsigned long dividend, unsigned long divisor)
{
    if (divisor == 0)
        return 0;

    unsigned long quotient = 0;
    unsigned long remainder = 0;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= (1UL << i);
        }
    }

    return quotient;
}

static unsigned long umod(unsigned long dividend, unsigned long divisor)
{
    if (divisor == 0)
        return 0;

    unsigned long remainder = 0;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if (remainder >= divisor) {
            remainder -= divisor;
        }
    }

    return remainder;
}

/* Software multiplication for RV32I (no M extension) */
static uint32_t umul(uint32_t a, uint32_t b)
{
    uint32_t result = 0;
    while (b) {
        if (b & 1)
            result += a;
        a <<= 1;
        b >>= 1;
    }
    return result;
}

/* Provide __mulsi3 for GCC */
uint32_t __mulsi3(uint32_t a, uint32_t b)
{
    return umul(a, b);
}

/* Simple integer to hex string conversion */
static void print_hex(unsigned long val)
{
    char buf[20];
    char *p = buf + sizeof(buf) - 1;
    *p = '\n';
    p--;

    if (val == 0) {
        *p = '0';
        p--;
    } else {
        while (val > 0) {
            int digit = val & 0xf;
            *p = (digit < 10) ? ('0' + digit) : ('a' + digit - 10);
            p--;
            val >>= 4;
        }
    }

    p++;
    printstr(p, (buf + sizeof(buf) - p));
}

/* Simple integer to decimal string conversion */
static void print_dec(unsigned long val)
{
    char buf[20];
    char *p = buf + sizeof(buf) - 1;
    *p = '\n';
    p--;

    if (val == 0) {
        *p = '0';
        p--;
    } else {
        while (val > 0) {
            *p = '0' + umod(val, 10);
            p--;
            val = udiv(val, 10);
        }
    }

    p++;
    printstr(p, (buf + sizeof(buf) - p));
}


/* ============= UF8 Encode / Decode Declaration ============= */

/* Assembly versions */
extern uint32_t uf8_decode_asm(uint32_t x);
extern uint32_t uf8_encode_asm(uint32_t x);

/* C versions (linked with different optimization levels) */
extern uint32_t uf8_decode_O0(uint32_t x);
extern uint32_t uf8_encode_O0(uint32_t x);
extern uint32_t uf8_decode_O2(uint32_t x);
extern uint32_t uf8_encode_O2(uint32_t x);
extern uint32_t uf8_decode_O3(uint32_t x);
extern uint32_t uf8_encode_O3(uint32_t x);

/* ============= Test Suite ============= */

typedef uint32_t (*uf8_func)(uint32_t);
typedef void (*test_func_t)(uf8_func encode, uf8_func decode);

static void run_test(test_func_t test_func, uf8_func encode, uf8_func decode)
{
    uint64_t start_cycles, end_cycles, cycles_elapsed;
    uint64_t start_instret, end_instret, instret_elapsed;

    start_cycles = get_cycles();
    start_instret = get_instret();

    test_func(encode, decode);

    end_cycles = get_cycles();
    end_instret = get_instret();

    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n\n");
}

static void test_UF8(uf8_func encode, uf8_func decode) {
    for (int i = 0; i < 256; i++) {
        uint32_t val = decode(i);
        uint32_t back = encode(val);
        if (back != i) {
            TEST_LOGGER("UF8 Encode/Decode test failed for input: ");
            print_hex(i);
            TEST_LOGGER("  Decoded value: ");
            print_hex(val);
            TEST_LOGGER("  Re-encoded value: ");
            print_hex(back);
        }
    }
    TEST_LOGGER("UF8 Encode/Decode test passed for all inputs.\n");
}


int main(void)
{
    TEST_LOGGER("\n=== UF8 Encode/Decode Tests ===\n\n");

    TEST_LOGGER("Test0 : UF8 Encode/Decode by my self assembly\n");
    run_test(test_UF8, uf8_encode_asm, uf8_decode_asm);

    TEST_LOGGER("Test1 : UF8 Encode/Decode by O0 C version\n");
    run_test(test_UF8, uf8_encode_O0, uf8_decode_O0);

    TEST_LOGGER("Test2 : UF8 Encode/Decode by O2 C version\n");
    run_test(test_UF8, uf8_encode_O2, uf8_decode_O2);

    TEST_LOGGER("Test3 : UF8 Encode/Decode by O3 C version\n");
    run_test(test_UF8, uf8_encode_O3, uf8_decode_O3);

    return 0;
}