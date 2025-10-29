#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static int clz(uint32_t x){
    if(!x) return 32;
    int n = 0;
    if((x & 0xFFFF0000) == 0) { n += 16; x <<= 16; }
    if((x & 0xFF000000) == 0) { n += 8; x <<= 8; }
    if((x & 0xF0000000) == 0) { n += 4; x <<= 4; }
    if((x & 0xC0000000) == 0) { n += 2; x <<= 2; }
    if((x & 0x80000000) == 0) { n += 1; }
    return n;
}

static uint64_t mul32(uint32_t a, uint32_t b)
{
    uint64_t result = 0;
    for(int i = 0; i < 32; i++) {
        if (b & (1U << i)) {
            result += ((uint64_t)a << i);
        }
    }
    return result;
}

static const uint16_t rsqrt_table[32] = {
    65536, 46341, 32768, 23170, 16384,
    11585, 8192, 5793, 4096, 2896,
    2048, 1448, 1024, 724, 512,
    362, 256, 181, 128, 90,
    64, 45, 32, 23, 16,
    11, 8, 6, 4, 3,
    2, 1
};

uint32_t rsqrt(uint32_t x)
{
    if (x == 0) return 0xFFFFFFFF;
    if (x == 1) return 65536;
    
    int exp = 31 - clz(x);

    uint32_t y = rsqrt_table[exp];

    // Linear interpolation
    if(x > (1u << exp)){
        uint32_t y_next = (exp < 31) ? rsqrt_table[exp + 1] : 0;
        uint32_t delta = y - y_next;
        uint32_t frac = ((x - (1u << exp)) << 16) / (1u << exp);
        y = y - (uint32_t) ((delta * frac) >> 16);
    }

    // Newton-Raphson iterations
    for(int iter = 0; iter < 6; iter++) {
        uint32_t y2 = (uint32_t)(mul32(y, y) >> 16);
        uint32_t xy2 = (uint32_t)(mul32(x, y2) >> 16);
        y = (uint32_t)((mul32(y, (3u << 16) - xy2)) >> 17);
    }
    return y;
}