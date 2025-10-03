#include <stdio.h>



/*unsigned popcount (unsigned u)
{
    u = (u & 0x55555555) + ((u >> 1) & 0x55555555);
    u = (u & 0x33333333) + ((u >> 2) & 0x33333333);
    u = (u & 0x0F0F0F0F) + ((u >> 4) & 0x0F0F0F0F);
    u = (u & 0x00FF00FF) + ((u >> 8) & 0x00FF00FF);
    u = (u & 0x0000FFFF) + ((u >> 16) & 0x0000FFFF);
    return u;
}
*/

int numberOfSteps(int num) {
    if (num == 0) return 0;

    int bits = 32 - __builtin_clz(num);

    int ones = __builtin_popcount(num);

    return (bits - 1) + ones;
}

int main() {

    int tests[20] = {
        0, 1, 2, 3, 4, 7, 8, 14, 15, 16,
        31, 32, 63, 64, 123, 255, 256, 1023, 1024, 0xFFFFFFFF
    };

    int expected[20] = {
        0, 1, 2, 3, 3, 5, 4, 6, 7, 5,
        9, 6, 11, 7, 12, 15, 9, 19, 11, 63
    };

    for (int i = 0; i < 20; i++) {
        int result = numberOfSteps(tests[i]);
        printf("Test %d: num=%d -> steps=%d (expected %d)%s\n",
            i+1, tests[i], result, expected[i],
            (result == expected[i]) ? " Passed" : " Failed");
    }

    return 0;
}