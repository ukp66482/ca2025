#include <stdio.h>

int numberOfSteps(int num) {
    if (num == 0) return 0;

    int bits = 32 - __builtin_clz(num);

    int ones = __builtin_popcount(num);

    return (bits - 1) + ones;
}

int main() {
    int test1 = 14; // Expected output: 6
    int test2 = 8;  // Expected output: 4
    int test3 = 123; // Expected output: 12

    printf("Test 1: %d steps\n", numberOfSteps(test1));
    printf("Test 2: %d steps\n", numberOfSteps(test2));
    printf("Test 3: %d steps\n", numberOfSteps(test3));

    return 0;
}

/*
unsigned popcount (unsigned u)
{
    u = (u & 0x55555555) + ((u >> 1) & 0x55555555);
    u = (u & 0x33333333) + ((u >> 2) & 0x33333333);
    u = (u & 0x0F0F0F0F) + ((u >> 4) & 0x0F0F0F0F);
    u = (u & 0x00FF00FF) + ((u >> 8) & 0x00FF00FF);
    u = (u & 0x0000FFFF) + ((u >> 16) & 0x0000FFFF);
    return u;
}
*/