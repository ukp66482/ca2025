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

static uint64_t mul32(uint32_t a, uint32_t b){
    uint64_t result = 0;
    for(int i = 0; i < 32; i++) {
        if (b & (1U << i)) {
            result += ((uint64_t)a << i);
        }
    }
    return result;
}

static const uint32_t rsqrt_table[32] = {
    65536, 46341, 32768, 23170, 16384,
    11585, 8192, 5793, 4096, 2896,
    2048, 1448, 1024, 724, 512,
    362, 256, 181, 128, 90,
    64, 45, 32, 23, 16,
    11, 8, 6, 4, 3,
    2, 1
};

uint32_t rsqrt(uint32_t x){
    if (x == 0) return 0xFFFFFFFF;
    if (x == 1) return 65536;
    
    int exp = 31 - clz(x);

    uint32_t y = rsqrt_table[exp];

    // Linear interpolation
    if(x > (1u << exp)){
        uint32_t y_next = (exp < 31) ? rsqrt_table[exp + 1] : 0;
        uint32_t delta = y - y_next;
        uint64_t numer = ((uint64_t)(x - (1u << exp)) << 16);
        uint32_t frac = (uint32_t)(numer >> exp);
        y = y - (uint32_t)((mul32(delta, frac)) >> 16);
    }

    // Newton-Raphson iterations
    for(int iter = 0; iter < 2; iter++) {
        uint64_t y_sq = mul32(y, y);
        uint32_t y2 = (uint32_t)(y_sq >> 16);
        uint64_t xy2 = (uint64_t)mul32(x, y2);
        uint64_t factor_num = (3u << 16);
        factor_num = (xy2 >= factor_num) ? 0 : (factor_num - xy2);
        uint32_t factor = (uint32_t)(factor_num >> 1);
        y = (uint32_t)((mul32(y, factor)) >> 16);
    }
    return y;
}
