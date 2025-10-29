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


/* ============= Hanoi Tower Solver Declaration ============= */

/* Assembly versions */
extern uint32_t hanoi_iter_asm(uint32_t n);

/* C versions (linked with different optimization levels) */
extern uint32_t hanoi_rec_wrapper_O0(uint32_t n);
extern uint32_t hanoi_rec_wrapper_O2(uint32_t n);
extern uint32_t hanoi_rec_wrapper_O3(uint32_t n);

extern uint32_t hanoi_iter_O0(uint32_t n);
extern uint32_t hanoi_iter_O2(uint32_t n);
extern uint32_t hanoi_iter_O3(uint32_t n);

/* ============= Test Suite ============= */

typedef uint32_t (*hanoi_func)(uint32_t);
typedef void (*test_func_t)(hanoi_func solver, uint32_t max_disks);

static void run_test(test_func_t test_func, hanoi_func solver, uint32_t disks)
{
    uint64_t start_cycles, end_cycles, cycles_elapsed;
    uint64_t start_instret, end_instret, instret_elapsed;

    start_cycles = get_cycles();
    start_instret = get_instret();

    test_func(solver, disks);

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

static void hanoi_test_suite(hanoi_func solver, uint32_t disks)
{
    uint32_t moves = solver(disks);
    TEST_LOGGER("Disks: ");
    print_dec(disks);
    TEST_LOGGER("Moves: ");
    print_dec(moves);
    TEST_LOGGER("\n");
}

int main(void)
{
    TEST_LOGGER("\n=== Hanoi Tower Tests ===\n\n");
    const uint32_t max_disks = 15;

    TEST_LOGGER("Testing hanoi_tower (Assembly iterative)...\n");
    run_test(hanoi_test_suite, hanoi_iter_asm, max_disks);
    
    TEST_LOGGER("Testing hanoi_tower (C iterative O0)...\n");
    run_test(hanoi_test_suite, hanoi_iter_O0, max_disks);

    TEST_LOGGER("Testing hanoi_tower (C iterative O2)...\n");
    run_test(hanoi_test_suite, hanoi_iter_O2, max_disks);

    TEST_LOGGER("Testing hanoi_tower (C iterative O3)...\n");
    run_test(hanoi_test_suite, hanoi_iter_O3, max_disks);

    TEST_LOGGER("Testing hanoi_tower (C recursive O0)...\n");
    run_test(hanoi_test_suite, hanoi_rec_wrapper_O0, max_disks);

    TEST_LOGGER("Testing hanoi_tower (C recursive O2)...\n");
    run_test(hanoi_test_suite, hanoi_rec_wrapper_O2, max_disks);

    TEST_LOGGER("Testing hanoi_tower (C recursive O3)...\n");
    run_test(hanoi_test_suite, hanoi_rec_wrapper_O3, max_disks);

    return 0;
}