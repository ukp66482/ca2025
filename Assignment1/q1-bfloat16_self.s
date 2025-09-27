.data
    BF16_SIGN_MASK: .word 0x8000
    BF16_EXP_MASK:  .word 0x7F80
    BF16_MANT_MASK: .word 0x007F
    BF16_EXP_BIAS:  .word 127
    BF16_ALL_MASK:  .word 0x7FFF           # all bits except sign bit
    
    specialOKmsg:   .string "Special values: PASS\n"
    specialFAILmsg: .string "Special values: FAIL\n"
    
    specialValues:  .word 0x7F80, 0xFF80, 0x7FC0, 0x0000, 0x8000
    
    specialResults: .word 0, 1, 0
                    .word 0, 1, 0
                    .word 1, 0, 0
                    .word 0, 0, 1
                    .word 0, 0, 1

    convertOKmsg:   .string "Basic conversions: PASS\n"
    convertFAILmsg: .string "Basic conversions: FAIL\n"
    
    convert_FP32:   .word 0x00000000, 0x3F800000, 0xBF800000, 0x40000000 
                    .word 0xC0000000, 0x3F000000, 0xBF000000, 0x40490FD0
                    .word 0xC0490FD0, 0x501502F9, 0xD01502F9 

    convert_BF16:   .word 0x0000, 0x3F80, 0xBF80, 0x4000
                    .word 0xC000, 0x3F00, 0xBF00, 0x4049
                    .word 0xC049, 0x5015, 0xD015

    converted_FP32: .word 0x00000000, 0x3F800000, 0xBF800000, 0x40000000
                    .word 0xC0000000, 0x3F000000, 0xBF000000, 0x40490000
                    .word 0xC0490000, 0x50150000, 0xD0150000
.text
main:
    #jal ra, CONVERT_TEST
    jal  ra, SPECIAL_TEST
    li   a7, 10
    ecall

BF16_EXP_ALL1:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    la   t0, BF16_EXP_MASK
    lw   t0, 0(t0)                         # t0 = BF16_EXP_MASK
    and  t1, a0, t0                        # t1 = a0 & BF16_EXP_MASK
    bne  t1, t0, BF16_EXP_NOTALL1          # if (a0 & BF16_EXP_MASK) != BF16_EXP_MASK, go to NOTALL1
    addi a0, x0, 1                         # exponent is all 1 return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_EXP_NOTALL1:
    addi a0, x0, 0                         # exponent is not all 1 return 0
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_MANT_NOT0:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    la   t0, BF16_MANT_MASK
    lw   t0, 0(t0)                         # t0 = BF16_MANT_MASK
    and  t1, a0, t0                        # t1 = a0 & BF16_MANT_MASK
    beq  t1, x0, BF16_MANT0
    addi a0, x0, 1                         # mantissa is not 0 return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_MANT0:
    lw   ra, 4(sp)
    addi sp, sp, 8
    addi a0, x0, 0                         # mantissa is 0 return 0
    ret

BF16_ISNAN:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    jal  ra, BF16_EXP_ALL1
    beq  a0, x0, BF16_NOTNAN               # if exponent is not all 1, go to NOTNAN
    lw   a0, 0(sp)                         # load original a0
    jal  ra, BF16_MANT_NOT0
    beq  a0, x0, BF16_NOTNAN               # if mantissa is 0, go to NOTNAN
    addi a0, x0, 1                         # is NaN return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_NOTNAN:
    addi a0, x0, 0                         # not NaN return 0
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_ISINF:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    jal  ra, BF16_EXP_ALL1
    beq  a0, x0, BF16_NOTINF               # if exponent is not all 1, go to NOTINF
    lw   a0, 0(sp)                         # load original a0
    jal  ra, BF16_MANT_NOT0                # a0 = 1 if mantissa is not 0 else 0
    bne  a0, x0, BF16_NOTINF               # if mantissa is not 0, go to NOTINF  
    addi a0, x0, 1                         # is Inf return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_NOTINF:
    addi a0, x0, 0                         # not Inf return 0
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_ISZERO:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    la   t0, BF16_ALL_MASK
    lw   t0, 0(t0)                         # t0 = BF16_ALL_MASK
    and  t1, a0, t0                        # t1 = a0 & BF16_ALL_MASK
    bne  t1, x0, BF16_NOTZERO              # if (a0 & BF16_ALL_MASK) != 0, go to NOTZERO
    addi a0, x0, 1                         # is zero return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_NOTZERO:
    addi a0, x0, 0                         # not zero return 0  
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

F32_TO_BF16:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    srli t0, a0, 23                         # t0 = exponent + mantissa
    andi t0, t0, 0xFF                       # t0 = exponent + 0x7F
    addi t1, x0, 0xFF                       # t1 = 0xFF
    beq  t0, t1, F32_TO_BF16_INF_NAN        # if exponent == 0xFF, go to INF_NAN

    srli t0, a0, 16                         # t0 = f32bits >> 16
    andi t0, t0, 1                          # t0 = (f32bits >> 16) & 1 = tmp
    add  a0, a0, t0                         # a0 = f32bits + tmp
    li   t1, 0x7FFF                         # t1 = 0x7FFF
    add  a0, a0, t1                         # a0 = f32bits + tmp + 0x7FFF
    srli a0, a0, 16                         # a0 = f32bits >> 16
    lw   ra, 4(sp)             
    addi sp, sp, 8
    ret

F32_TO_BF16_INF_NAN:
    srli a0, a0, 16                         # a0 = f32bits >> 16
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret   

BF16_TO_F32:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    slli a0, a0, 16                         # a0 = bf16 << 16       
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

SPECIAL_TEST:
    addi sp, sp, -4
    sw   ra, 0(sp)
    addi s0, x0, 0                          # i = 0
    la   s1, specialValues
    la   s2, specialResults
    addi s3, x0, 5

SPECIAL_TEST_LOOP:
    beq  s0, s3, SPECIAL_ALL_PASS           # if i == 5, all pass

    slli s4, s0, 2                          # s4 = i * 4
    add  s5, s1, s4                         # s5 = &specialValues[i]
    lw   s6, 0(s5)                          # s6 = specialValues[i]
    lw   s7, 0(s2)                          # s7 = &specialResults[i][0]
    mv   a0, s6
    jal  ra, BF16_ISNAN
    bne  a0, s7, SPECIAL_FAIL
    lw   s7, 4(s2)                          # s7 = &specialResults[i][1]
    mv   a0, s6
    jal  ra, BF16_ISINF
    bne  a0, s7, SPECIAL_FAIL
    lw   s7, 8(s2)                          # s7 = &specialResults
    mv   a0, s6
    jal  ra, BF16_ISZERO
    bne  a0, s7, SPECIAL_FAIL
    addi s2, s2, 12                         # s2 = &specialResults[i+1][0]
    addi s0, s0, 1
    jal  x0, SPECIAL_TEST_LOOP

SPECIAL_FAIL:
    la   a0, specialFAILmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

SPECIAL_ALL_PASS:
    la   a0, specialOKmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

CONVERT_TEST:
    addi sp, sp, -4
    sw   ra, 0(sp)
    addi s0, x0, 0
    la   s1, convert_FP32
    la   s2, convert_BF16
    la   s3, converted_FP32
    addi s4, x0, 11

CONVERT_TEST_LOOP:
    beq  s0, s4, CONVERT_ALL_PASS           # if i == 11, all pass

    slli s5, s0, 2                          # s5 = i * 4
    add  s6, s1, s5                         # s6 = &convert_FP32[i]
    lw   a0, 0(s6)                          # a0 = convert_FP32[i]
    jal  ra, F32_TO_BF16                          

    slli s5, s0, 2                          # s5 = i * 4
    add  s6, s2, s5                         # s6 = &convert_BF16[i] 
    lhu  t0, 0(s6)                          # t0 = convert_BF16[i]
    bne  a0, t0, CONVERT_FAIL

    jal  ra, BF16_TO_F32
    slli s5, s0, 2                          # s5 = i * 4
    add  s6, s3, s5
    lw   t0, 0(s6)
    bne  a0, t0, CONVERT_FAIL

    addi s0, s0, 1
    jal  x0, CONVERT_TEST_LOOP

CONVERT_FAIL:
    la   a0, convertFAILmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

CONVERT_ALL_PASS:
    la   a0, convertOKmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
