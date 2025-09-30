.data
    BF16_SIGN_MASK: .word 0x8000
    BF16_EXP_MASK:  .word 0x7F80
    BF16_MANT_MASK: .word 0x007F
    BF16_EXP_BIAS:  .word 127
    BF16_ALL_MASK:  .word 0x7FFF            # all bits except sign bit
    
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

    specialOKmsg:   .string "Special values: PASS\n"
    specialFAILmsg: .string "Special values: FAIL\n"
    
    specialValues:  .word 0x7F80, 0xFF80, 0x7FC0, 0x0000, 0x8000
    
    specialResults: .word 0, 1, 0
                    .word 0, 1, 0
                    .word 1, 0, 0
                    .word 0, 0, 1
                    .word 0, 0, 1

    arithmeticOKmsg:   .string "Arithmetic: PASS\n"
    arithmeticFAILmsg: .string "Arithmetic: FAIL\n"

    arithmeticValues_a: .word 0x3F800000, 0x40000000, 0x40400000, 0x41200000
                        .word 0x40800000, 0x41100000
                        
    arithmeticValues_b: .word 0x40000000, 0x3F800000, 0x40800000, 0x40000000

    arithmeticResults: .word 0x40400000, 0x3F800000, 0x41400000, 0x40A00000
                       .word 0x40000000, 0x40400000

    compareOKmsg:   .string "Comparisons: PASS\n"
    compareFAILmsg: .string "Comparisons: FAIL\n"

    compareValues:  .word 0x3F800000, 0x40000000, 0x3F800000, 0x7FC0

    compareResults: .word 1, 0
                    .word 1, 0, 0
                    .word 1, 0
                    .word 0, 0, 0

    roundingOKmsg:   .string "Rounding: PASS\n"
    roundingFAILmsg: .string "Rounding: FAIL\n"

    roundingValues:  .word 0x3FC00000, 0x3F800347
    roundingResults: .word 0x3FC00000, 0x3F800000

.text
main:
    #jal ra, CONVERT_TEST
    #jal  ra, SPECIAL_TEST
    #jal  ra, COMPARE_TEST
    jal  ra, ROUNDING_TEST
    li   a7, 10
    ecall

# BF16 special value check
BF16_EXP_ALL1:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    la   t0, BF16_EXP_MASK
    lw   t0, 0(t0)                          # t0 = BF16_EXP_MASK
    and  t1, a0, t0                         # t1 = a0 & BF16_EXP_MASK
    bne  t1, t0, BF16_EXP_NOTALL1           # if (a0 & BF16_EXP_MASK) != BF16_EXP_MASK, go to NOTALL1
    addi a0, x0, 1                          # exponent is all 1 return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_EXP_NOTALL1:
    addi a0, x0, 0                          # exponent is not all 1 return 0
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_MANT_NOT0:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    la   t0, BF16_MANT_MASK
    lw   t0, 0(t0)                          # t0 = BF16_MANT_MASK
    and  t1, a0, t0                         # t1 = a0 & BF16_MANT_MASK
    beq  t1, x0, BF16_MANT0
    addi a0, x0, 1                          # mantissa is not 0 return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_MANT0:
    lw   ra, 4(sp)
    addi sp, sp, 8
    addi a0, x0, 0                          # mantissa is 0 return 0
    ret

BF16_ISNAN:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    jal  ra, BF16_EXP_ALL1
    beq  a0, x0, BF16_NOTNAN                # if exponent is not all 1, go to NOTNAN
    lw   a0, 0(sp)                          # load original a0
    jal  ra, BF16_MANT_NOT0
    beq  a0, x0, BF16_NOTNAN                # if mantissa is 0, go to NOTNAN
    addi a0, x0, 1                          # is NaN return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_NOTNAN:
    addi a0, x0, 0                          # not NaN return 0
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_ISINF:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    jal  ra, BF16_EXP_ALL1
    beq  a0, x0, BF16_NOTINF                # if exponent is not all 1, go to NOTINF
    lw   a0, 0(sp)                          # load original a0
    jal  ra, BF16_MANT_NOT0                 # a0 = 1 if mantissa is not 0 else 0
    bne  a0, x0, BF16_NOTINF                # if mantissa is not 0, go to NOTINF  
    addi a0, x0, 1                          # is Inf return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_NOTINF:
    addi a0, x0, 0                          # not Inf return 0
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_ISZERO:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    la   t0, BF16_ALL_MASK
    lw   t0, 0(t0)                          # t0 = BF16_ALL_MASK
    and  t1, a0, t0                         # t1 = a0 & BF16_ALL_MASK
    bne  t1, x0, BF16_NOTZERO               # if (a0 & BF16_ALL_MASK) != 0, go to NOTZERO
    addi a0, x0, 1                          # is zero return 1
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

BF16_NOTZERO:
    addi a0, x0, 0                          # not zero return 0  
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

#############################################################################
# BF16 Arithemetic operations
BF16_ADD:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   a1, 4(sp)                         # 4(sp) = b
    sw   a0, 0(sp)                         # 0(sp) = a                    

    srl  s0, a0, 15                        # s0 = sign_a
    srl  s1, a1, 15                        # s1 = sign_b
    srl  s2, a0, 7
    srl  s3, a1, 7
    andi s2, s2, 0xFF                      # s2 = exp_a
    andi s3, s3, 0xFF                      # s3 = exp_b
    andi s4, a0, 0x7F                      # s4 = mant_a
    andi s5, a1, 0x7F                      # s5 = mant_b
    addi t0, x0, 0xFF
    beq  s2, t0, 1f                        # if exp_a == 0xFF, go to 1
    beq  s3, t0, RETURN_B                  # if exp_b == 0xFF, go to RETURN_B
    beq  s2, x0, 3f                        # if exp_a == 0, go to 3    

ADD_A_NOT_ZERO:
    beq  s3, x0, 4f                        # if exp_b == 0, go to 4

ADD_B_NOT_ZERO:
    bne  s2, x0, 5f                        # if exp_a != 0, go to 5

ADD_EXP_A_NOT_ZERO:    
    bne  s3, x0, 6f                        # if exp_b != 0, go to 6    
    jal  x0, ADD_EXP_B_NOT_ZERO

1:
    bne s4, x0, RETURN_A                   # if mant_a != 0, go to 2
    beq s3, t0, 2f                         # if mant_b == 0xFF, go to 3
    jal x0, RETURN_A                       # else return a

2: 
    bne s5, x0, RETURN_B                   # if mant_b != 0, go to RETURN_B
    beq s0, s1, RETURN_B                   # if sign_a == sign_b, go to RETURN_B
    jal x0, RETURN_NAN                     # else return NAN

3:
    beq  s3, x0, RETURN_B                  # if exp_b == 0, go to RETURN_B
    jal  x0, ADD_A_NOT_ZERO

4:
    beq  s2, x0, RETURN_A                  # if exp_a == 0, go to RETURN_A
    jal  x0, ADD_B_NOT_ZERO

5:
    ori  s4, s4, 0x80                       # mant_a = mant_a | 0x80
    jal  x0, ADD_EXP_A_NOT_ZERO
6:
    ori  s5, s5, 0x80                       # mant_b = mant_b | 0x80
    jal  x0, ADD_EXP_B_NOT_ZERO

ADD_EXP_B_NOT_ZERO:
    sub  s7, s2, s3                        # s7 = exp_a - exp_b
    bgt  s7, x0, 1f                        # if exp_a > exp_b, go to 1        
    blt  s7, x0, 2f                        # if exp_a < exp_b, go to 2
    addi s9, s2, 0                         # s9 = result_exp = exp_a
    jal  x0, ADD_EXP_DONE

1:
    add  s9, s2, x0                        # s9 = result_exp = exp_a
    addi t0, x0, 8
    bgt  s7, t0, RETURN_A                  # if exp_a - exp_b > 8, go to RETURN_A
    jal  x0, ADD_EXP_DONE

2:  
    addi s9, s3, 0
    addi t0, x0, -8
    blt  s7, t0, RETURN_B                  # if exp_a - exp_b < -8, go to RETURN_B
    jal  x0, ADD_EXP_DONE 

ADD_EXP_DONE:
    bne s0, s1, ADD_DIFF_SIGN              # if sign_a != sign_b, go to ADD_DIFF_SIGN


ADD_SAME_SIGN: # sign_a == sign_b
    add  s8, s0, x0                        # s8 = result_sign = sign_a
    add  s10, s4, s5                       # s10 = mant_a + mant_b = result_mant
    andi t0, s10, 0x100                    # t0 = (mant_a + mant_b) & 0x100
    bne  t0, x0, 1f
    jal  x0, RETURN_ADD

1:  
    srli s10, s10, 1                       # result_mant = result_mant >> 1
    addi s9, s9, 1                         # result_exp = result_exp + 1
    addi t0, x0,0xFF
    beq  s9, t0, 2f                  
    bgt  s9, t0, 2f                        # if result_exp >= 0xFF, go to 2
    jal  x0, RETURN_ADD

2:  #return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    slli s11, s8, 15
    ori  s11, s11, 0x7F80
    mv   a0, s11
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

ADD_DIFF_SIGN: # sign_a != sign_b
    beq  s4, s5, 2f                        # if mant_a == mant_b, go to 2
    bgt  s4, s5, 2f                        # if mant_a > mant_b, go to 2
    addi  s8, s1, 0                        # s8 = result_sign = sign_b
    sub  s10, s5, s4                       # s10 = mant_b - mant_a = result_mant

1:
    beq  s10, x0, RETURN_ZERO              # if result_mant == 0, go to RETURN_ZERO

3:
    andi t0, s10, 0x80                     # t0 = result_mant & 0x80
    beq  t0, x0, 4f
    jal  x0, RETURN_ADD

4:  # normalize
    slli s10, s10, 1                       # result_mant = result_mant << 1
    addi s9, s9, -1                        # result_exp = result_exp - 1
    bgt  s9, x0, 3b                        # if result_exp > 0, go to 3
    jal  x0, RETURN_ZERO                   # else go to RETURN_ZERO            

2:
    addi s8, s0, 0                         # s8 = result_sign = sign_a
    sub  s10, s4, s5                       # s10 = mant_a - mant_b = result_mant
    jal  x0, 1b  


    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_A: # Return a
    lw   a0, 0(sp)
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_B: # Return b
    lw   a0, 4(sp)
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_NAN: # Return NAN
    li   a0, 0x7FC0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_ZERO:
    li   a0, 0x0000
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_ADD:
    slli t0, s8, 15                         # t0 = result_sign << 15
    andi t1, s9, 0xFF
    slli t1, t1, 7                          # t1 = result_exp
    andi t2, s10, 0x7F
    or   t3, t0, t1                         # t3 = (result_sign << 15) | result_exp
    or   t3, t3, t2                         # t3 = (result_sign << 15) | result_exp | result_mant
    mv   a0, t3
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

BF16_SUB:
BF16_MUL:
BF16_DIV:
BF16_SQRT:
#############################################################################

# BF16 comparisons
BF16_EQ:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   a1, 4(sp)                          # 4(sp) = b
    sw   a0, 0(sp)                          # 0(sp) = a
    jal  ra, BF16_ISNAN
    bne  a0, x0, 1f                         # if a is NaN, go to Not equal
    lw   a0, 4(sp)                          # load b
    jal  ra, BF16_ISNAN
    bne  a0, x0, 1f                         # if b is NaN, go to Not equal
    lw   a0, 0(sp)                          # load a
    jal  ra, BF16_ISZERO
    beq  a0, x0, 3f                         # if a is not zero, go to compare a and b
    lw   a0, 4(sp)                          # load b
    jal  ra, BF16_ISZERO
    beq  a0, x0, 3f                         # if b is not zero, go to compare a and b
    jal  x0, 2f                             # both a and b are zero, go to Equal

1: # Not Equal
    addi a0, x0, 0                          # Not Equal return 0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

2: # Equal
    addi a0, x0, 1                          # Equal return 1
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

3: # compare a and b
    lw   a0, 0(sp)                          # load a
    lw   a1, 4(sp)                          # load b
    beq  a0, a1, 2b                         # if a == b, go to Equal
    jal  x0, 1b                             # else go to Not Equal

BF16_LT: # a0 = a, a1 = b, return 1 if a < b else 0
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   a1, 4(sp)                          # 4(sp) = b
    sw   a0, 0(sp)                          # 0(sp) = a
    jal  ra, BF16_ISNAN
    bne  a0, x0, 1f                         # if a is NaN, go to Not Less
    lw   a0, 4(sp)                          # load b
    jal  ra, BF16_ISNAN
    bne  a0, x0, 1f                         # if b is NaN, go to Not Less
    lw   a0, 0(sp)                          # load a
    jal  ra, BF16_ISZERO
    beq  a0, x0, 3f                         # if a is not zero, go to check a and b signed bit
    lw   a0, 4(sp)                          # load b
    jal  ra, BF16_ISZERO
    beq  a0, x0, 3f                         # if b is not zero, go to check a and b signed bit
    jal  x0, 1f                             # both a and b are zero, go to Not Less

1: # Not Less
    addi a0, x0, 0                          # Not Less return 0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

2: # Less
    addi a0, x0, 1                          # Less return 1
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

3: # check a and b signed bit
    lw   a0, 0(sp)                          # load a
    lw   a1, 4(sp)                          # load b
    srli  t0, a0, 15                        # t0 = sign_a
    srli  t1, a1, 15                        # t1 = sign_b
    bne  t0, t1, 4f                         # if sign_a != sign_b, go to sign bit compare
    jal  x0, 5f                             # if sign_a == sign_b

4: # signed bit compare
    bgt  t0, t1, 2b                         # if sign_a > sign_b, go to Less
    jal  x0, 1b                             # else go to Not Less

5: # signed bit the same
    beq  t0, x0, 7f                         # if a_sign == 0, go to both pos
    jal  x0, 6f                             # if a_sign == 1, go to both neg

6: # both negative
    bgt  a0, a1, 2b                         # if a > b, go to Less
    jal  x0, 1b                             # else go to Not Less

7: # both positive
    blt  a0, a1, 2b                         # if a < b, go to Less
    jal  x0, 1b                             # else go to Not Less

BF16_GT: # a0 = a, a1 = b, return 1 if a > b else 0
    mv   t0, a0
    mv   a0, a1
    mv   a1, t0
    jal  x0, BF16_LT

# BF16 / FP32 conversion    
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

# Test routines
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

ARITHMETIC_TEST:
    addi sp, sp, -4
    sw   ra, 0(sp)
    addi s0, x0, 0
    la   a2, arithmeticValues_a
    la   a3, arithmeticValues_b
    la   a4, arithmeticResults

    
ARITHMETIC_FAIL:
    la   a0, arithmeticFAILmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

ARITHMETIC_ALL_PASS:
    la   a0, arithmeticOKmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

COMPARE_TEST:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   a0, compareValues
    lw   s0, 0(a0)                          # s0 = a
    lw   s1, 4(a0)                          # s1 = b
    lw   s2, 8(a0)                          # s2 = c
    lhu  s3, 12(a0)                         # s3 = nan
    la   s4, compareResults                 # s4 = compareResults

    mv   a0, s0
    jal  ra, F32_TO_BF16
    mv   s0, a0                             # s0 = bf16 of a
    mv   a0, s1
    jal  ra, F32_TO_BF16
    mv   s1, a0                             # s1 = bf16 of b
    mv   a0, s2
    jal  ra, F32_TO_BF16
    mv   s2, a0                             # s2 = bf16 of c
    
    mv   a0, s0
    mv   a1, s2                             # a0 = a, a1 = c
    jal  ra, BF16_EQ                        # eq a and c
    lw   t0, 0(s4)                          # t0 = compareResults[0]
    bne  a0, t0, COMPARE_FAIL

    mv   a0, s0
    mv   a1, s1                             # a0 = a, a1 = b
    jal  ra, BF16_EQ                        # eq a and b
    lw   t0, 4(s4)                          # t0 = compareResults[1]
    bne  a0, t0, COMPARE_FAIL

    mv a0, s0
    mv a1, s1                               # a0 = a, a1 = b
    jal ra, BF16_LT                         # lt a and b
    lw t0, 8(s4)                            # t0 = compareResults[2]
    bne a0, t0, COMPARE_FAIL

    mv a0, s1
    mv a1, s0                               # a0 = b, a1 = a
    jal ra, BF16_LT                         # lt b and a
    lw t0, 12(s4)                           # t0 = compareResults[3]
    bne a0, t0, COMPARE_FAIL

    mv a0, s0    
    mv a1, s2                               # a0 = a, a1 = c
    jal ra, BF16_LT                         # lt a and c
    lw t0, 16(s4)                           # t0 = compareResults[4]
    bne a0, t0, COMPARE_FAIL

    mv a0, s1
    mv a1, s0                               # a0 = b, a1 = a
    jal ra, BF16_GT                         # gt b and a
    lw t0, 20(s4)                           # t0 = compareResults[5]
    bne a0, t0, COMPARE_FAIL

    mv a0, s0
    mv a1, s1                               # a0 = a, a1 = b
    jal ra, BF16_GT                         # gt a and b
    lw t0, 24(s4)                           # t0 = compareResults[6]
    bne a0, t0, COMPARE_FAIL

    mv a0, s3                              
    mv a1, s3                               # a0 = nan, a1 = nan
    jal ra, BF16_EQ                         # eq nan and nan
    lw t0, 28(s4)                           # t0 = compareResults[7]
    bne a0, t0, COMPARE_FAIL

    mv a0, s3
    mv a1, s0                               # a0 = nan, a1 = a
    jal ra, BF16_LT                         # lt nan and a
    lw t0, 32(s4)                           # t0 = compareResults[8]
    bne a0, t0, COMPARE_FAIL

    mv a0, s3
    mv a1, s0                               # a0 = nan, a1 = a
    jal ra, BF16_GT                         # gt nan and a
    lw t0, 36(s4)                           # t0 = compareResults[9]
    bne a0, t0, COMPARE_FAIL
    jal  x0, COMPARE_ALL_PASS

COMPARE_FAIL:
    la   a0, compareFAILmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

COMPARE_ALL_PASS:
    la   a0, compareOKmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

ROUNDING_TEST:
    addi sp, sp, -4
    sw   ra, 0(sp)
    addi s0, x0, 0
    la   s1, roundingValues
    la   s2, roundingResults
    addi s3, x0, 2

ROUNDING_TEST_LOOP:
    beq  s0, s3, ROUNDING_ALL_PASS          # if i == 2, all pass
    slli s4, s0, 2                          # s4 = i * 4
    add  s5, s1, s4                         # s5 = &roundingValues[i]
    add  s6, s2, s4                         # s6 = &roundingResults[i]
    lw   a0, 0(s5)                          # a0 = roundingValues[i]
    lw   s7, 0(s6)                          # s7 = roundingResults[i]
    jal  ra, F32_TO_BF16                    # convert to bf16
    jal  ra, BF16_TO_F32                    # convert back to f32
    bne  a0, s7, ROUNDING_FAIL
    addi s0, s0, 1
    jal  x0, ROUNDING_TEST_LOOP

ROUNDING_FAIL:
    la   a0, roundingFAILmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

ROUNDING_ALL_PASS:
    la   a0, roundingOKmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret