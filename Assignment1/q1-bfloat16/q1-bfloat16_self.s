.data
    .equ BF16_SIGN_MASK, 0x8000
    .equ BF16_EXP_MASK, 0x7F80
    .equ BF16_MANT_MASK, 0x007F
    .equ BF16_EXP_BIAS, 127
    .equ BF16_ALL_MASK, 0x7FFF
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

    edge_caseOKmsg:   .string "Edge cases: PASS\n"
    edge_caseFAILmsg: .string "Edge cases: FAIL\n"

    edge_caseValues: .word 0x00000001, 0x7E967699, 0x006CE3EE

    edge_caseResults: .word 0x00000000, 0x7F800000, 0x00000000

    roundingOKmsg:   .string "Rounding: PASS\n"
    roundingFAILmsg: .string "Rounding: FAIL\n"

    roundingValues:  .word 0x3FC00000, 0x3F800347
    roundingResults: .word 0x3FC00000, 0x3F800000

.text
main:
    jal  ra, CONVERT_TEST
    jal  ra, SPECIAL_TEST
    jal  ra, ARITHMETIC_TEST
    jal  ra, COMPARE_TEST
    jal  ra, EDGE_CASE_TEST
    jal  ra, ROUNDING_TEST
    li   a7, 10
    ecall


#////////////////////////////////////////////   
#
#   BF16_EXP_ALL1 function
#
#   input: a0 = x, return 1 if exponent is all 1 else 0
#
#////////////////////////////////////////////
BF16_EXP_ALL1:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    li   t0, BF16_EXP_MASK
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


#////////////////////////////////////////////   
#
#   BF16_MANT_NOT0 function
#
#   input: a0 = x, return 1 if mantissa is not 0 else 0
#
#////////////////////////////////////////////
BF16_MANT_NOT0:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    li   t0, BF16_MANT_MASK                 # t0 = BF16_MANT_MASK
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

#////////////////////////////////////////////   
#
#   BF16_ISNAN function
#
#   input: a0 = x, return 1 if x is NaN else 0
#
#////////////////////////////////////////////
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

#////////////////////////////////////////////   
#
#   BF16_ISINF function
#
#   input: a0 = x, return 1 if x is Inf else 0
#
#////////////////////////////////////////////
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

#////////////////////////////////////////////   
#
#   BF16_ISZERO function
#
#   input: a0 = x, return 1 if x is zero else 0
#
#////////////////////////////////////////////
BF16_ISZERO:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    li   t0, BF16_ALL_MASK
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

#////////////////////////////////////////////   
#
#   BF16_ADD function
#
#   input: a0 = a, a1 = b
#   return: a0 = a + b
#
#////////////////////////////////////////////
BF16_ADD:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   a1, 4(sp)                          # 4(sp) = b
    sw   a0, 0(sp)                          # 0(sp) = a                    

    srli t1, a0, 15                         # t1 = sign_a
    srli t2, a1, 15                         # t2 = sign_b
    srli t3, a0, 7
    srli t4, a1, 7
    andi t3, t3, 0xFF                       # t3 = exp_a
    andi t4, t4, 0xFF                       # t4 = exp_b
    andi t5, a0, 0x7F                       # t5 = mant_a
    andi t6, a1, 0x7F                       # t6 = mant_b

    addi t0, x0, 0xFF
    beq  t3, t0, 1f                         # if exp_a == 0xFF, go to 1
    beq  t4, t0, RETURN_B                   # if exp_b == 0xFF, go to RETURN_B
    beq  t3, x0, 3f                         # if exp_a == 0, go to 3    

ADD_A_NOT_ZERO:
    beq  t4, x0, 4f                         # if exp_b == 0, go to 4

ADD_B_NOT_ZERO:
    bne  t3, x0, 5f                         # if exp_a != 0, go to 5

ADD_EXP_A_NOT_ZERO:    
    bne  t4, x0, 6f                         # if exp_b != 0, go to 6    
    jal  x0, ADD_EXP_B_NOT_ZERO

1:
    bne t5, x0, RETURN_A                    # if mant_a != 0, go to RETURN_A
    beq t6, t0, 2f                          # if mant_b == 0xFF, go to 2
    jal x0, RETURN_A                        # else return a

2: 
    bne t6, x0, RETURN_B                    # if mant_b != 0, go to RETURN_B
    beq t1, t2, RETURN_B                    # if sign_a == sign_b, go to RETURN_B
    jal x0, RETURN_NAN                      # else return NAN

3:
    beq  t5, x0, RETURN_B                   # if mant_a == 0, go to RETURN_B
    jal  x0, ADD_A_NOT_ZERO

4:
    beq  t6, x0, RETURN_A                   # if mant_b == 0, go to RETURN_A
    jal  x0, ADD_B_NOT_ZERO

5:
    ori  t5, t5, 0x80                       # mant_a = mant_a | 0x80
    jal  x0, ADD_EXP_A_NOT_ZERO
6:
    ori  t6, t6, 0x80                       # mant_b = mant_b | 0x80
    jal  x0, ADD_EXP_B_NOT_ZERO

ADD_EXP_B_NOT_ZERO:
    sub  a0, t3, t4                         # a0 = exp_a - exp_b
    bgt  a0, x0, 1f                         # if exp_a > exp_b, go to 1        
    blt  a0, x0, 2f                         # if exp_a < exp_b, go to 2
    addi a3, t3, 0                          # a3 = result_exp = exp_a
    jal  x0, ADD_EXP_DONE

1:
    addi  a3, t3, 0                         # a3 = result_exp = exp_a
    addi t0, x0, 8
    bgt  a0, t0, RETURN_A                   # if exp_a - exp_b > 8, go to RETURN_A
    srl  t6, t6, a0                         # mant_b = mant_b >> (exp_a - exp_b)
    jal  x0, ADD_EXP_DONE

2:  
    addi a3, t4, 0
    addi t0, x0, -8
    blt  a0, t0, RETURN_B                   # if exp_a - exp_b < -8, go to RETURN_B
    sub  a0, x0, a0                         # a0 = -a0
    srl  t5, t5, a0                         # mant_a = mant_a >> (exp_b - exp_a)
    jal  x0, ADD_EXP_DONE

ADD_EXP_DONE:
    bne t1, t2, ADD_DIFF_SIGN               # if sign_a != sign_b, go to ADD_DIFF_SIGN


ADD_SAME_SIGN:
    addi a2, t1, 0                          # a2 = result_sign = sign_a
    add  a4, t5, t6                         # a4 = mant_a + mant_b = result_mant
    andi t0, a4, 0x100                      # t0 = (mant_a + mant_b) & 0x100
    bne  t0, x0, 1f
    jal  x0, RETURN_ADD

1:  
    srli a4, a4, 1                          # result_mant = result_mant >> 1
    addi a3, a3, 1                          # result_exp = result_exp + 1
    addi t0, x0,0xFF
    beq  a3, t0, 2f                         # if result_exp == 0xFF, go to 2
    bgt  a3, t0, 2f                         # if result_exp >= 0xFF, go to 2
    jal  x0, RETURN_ADD

2:  
    slli a0, a2, 15                         # return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    li   t0, BF16_EXP_MASK
    or   a0, a0, t0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

ADD_DIFF_SIGN:
    beq  t5, t6, 2f                         # if mant_a == mant_b, go to 2
    bgt  t5, t6, 2f                         # if mant_a > mant_b, go to 2
    addi  a2, t2, 0                         # a2 = result_sign = sign_b
    sub   a4, t6, t5                        # a4 = mant_b - mant_a = result_mant

1:
    beq  a4, x0, RETURN_ZERO                # if result_mant == 0, go to RETURN_ZERO

3:
    andi t0, a4, 0x80                       # t0 = result_mant & 0x80
    beq  t0, x0, 4f
    jal  x0, RETURN_ADD

4:
    slli a4, a4, 1                          # result_mant = result_mant << 1
    addi a3, a3, -1                         # result_exp = result_exp - 1
    bgt  a3, x0, 3b                         # if result_exp > 0, go to 3
    jal  x0, RETURN_ZERO                    # else go to RETURN_ZERO

2:
    addi a2, t1, 0                          # a2 = result_sign = sign_a
    sub  a4, t5, t6                         # a4 = mant_a - mant_b = result_mant
    jal  x0, 1b  

    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_A:
    lw   a0, 0(sp)
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_B:
    lw   a0, 4(sp)
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_NAN:
    li   a0, 0x7FC0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_ZERO:
    addi a0, x0, 0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_ADD:
    slli a0, a2, 15                        # a0 = result_sign << 15
    andi t0, a3, 0xFF
    slli t0, t0, 7
    or   a0, a0, t0                        # a0 = (result_sign << 15) | result_exp
    andi t0, a4, 0x7F
    or   a0, a0, t0                        # a0 = (result_sign << 15) | (result_exp << 7) | result_mant
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

#////////////////////////////////////////////   
#
#   BF16_SUB function
#
#   input: a0 = a, a1 = b
#   return: a0 = a - b
#
#////////////////////////////////////////////
BF16_SUB:
    li   t0, BF16_SIGN_MASK
    xor  a1, a1, t0                        # b = b ^ 0x8000
    jal  x0, BF16_ADD

#////////////////////////////////////////////   
#
#   BF16_MUL function
#
#   input: a0 = a, a1 = b
#   return: a0 = a * b
#
#////////////////////////////////////////////
BF16_MUL:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   a1, 4(sp)                          # 4(sp) = b
    sw   a0, 0(sp)                          # 0(sp) = a                    

    srli t1, a0, 15                         # t1 = sign_a
    srli t2, a1, 15                         # t2 = sign_b
    srli t3, a0, 7
    srli t4, a1, 7
    andi t3, t3, 0xFF                       # t3 = exp_a
    andi t4, t4, 0xFF                       # t4 = exp_b
    andi t5, a0, 0x7F                       # t5 = mant_a
    andi t6, a1, 0x7F                       # t6 = mant_b
    xor  a2, t1, t2                         # a2 = result_sign = sign_a ^ sign_b
    addi t0, x0, 0xFF
    beq  t3, t0, 1f                         # if exp_a == 0xFF, go to 1
    jal  x0, CHECK_B

1:
    bne t5, x0, RETURN_A                    # if mant_a != 0, go to RETURN_A
    beq t4, t0, 2f                          # if exp_b == 0, go to 2
    jal x0, 3f                              # return inf


2:  
    beq t6, x0, RETURN_NAN                  # if mant_b == 0, go to RETURN_NAN
    jal x0, 3f                              # return inf

3:                                          # NAN
    slli a0, a2, 15
    li   t0, BF16_EXP_MASK
    or   a0, a0, t0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

CHECK_B:
    beq  t4, t0, 1f                         # if exp_b == 0xFF, go to 1
    jal  x0, CHECK_ZERO

1:
    bne t6, x0, RETURN_B                    # if mant_b != 0, go to RETURN_B
    beq t3, t0, 2f                          # if exp_a == 0, go to 2
    jal x0, 3b                              # return inf


2:  
    beq t5, x0, RETURN_NAN                  # if mant_a == 0, go to RETURN_NAN
    jal x0, 3b                              # return inf

CHECK_ZERO:
    beq t3, x0, CHECK_A_ZERO                # if exp_a == 0, check mant_a
    beq t4, x0, CHECK_B_ZERO                # if exp_b == 0, check mant_b
    jal  x0, CONT_MUL              

CHECK_A_ZERO:
    beq t5, x0, RETURN_ZERO_SIGN            # if mant_a == 0 -> return 0
    jal  x0, CONT_MUL              

CHECK_B_ZERO:
    beq t6, x0, RETURN_ZERO_SIGN            # if mant_b == 0 -> return 0
    jal  x0, CONT_MUL              

RETURN_ZERO_SIGN:
    slli a0, a2, 15                         # a0 = result_sign << 15
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

CONT_MUL:
    addi a3, x0, 0                          # a3 = exp_adjust = 0    
    beq  t3, x0, 1f                         # if exp_a == 0, go to 1
    ori  t5, t5, 0x80                       # mant_a = mant_a | 0x80
    jal  x0, 3f

1: 
    andi t0, t5, 0x80                       # t0 = mant_a & 0x80
    beq  t0, x0, 2f                         # if mant_a & 0x80 == 0, go to 2    
    addi t3, x0, 1                          # exp_a = 1
    jal  x0, 3f

2:
    slli t5, t5, 1                          # mant_a = mant_a << 1
    addi a3, a3, -1                         # exp_adjust = exp_adjust - 1
    jal  x0, 1b                             # go to 1

3: 
    beq  t4, x0, 4f                         # if exp_b == 0, go to 4
    ori  t6, t6, 0x80                       # mant_b = mant_b | 0x80
    jal  x0, SHIFT_ADD

4:  
    andi t0, t6, 0x80                       # t0 = mant_b & 0x80
    beq  t0, x0, 5f                         # if mant_b & 0x80 == 0, go to 5    
    addi t4, x0, 1                          # exp_b = 1
    jal  x0, SHIFT_ADD

5:
    slli t6, t6, 1                          # mant_b = mant_b << 1
    addi a3, a3, -1                         # exp_adjust = exp_adjust - 1
    jal  x0, 4b                             # go to 4

SHIFT_ADD:
    addi a4, x0, 0                          # a4 = result_mant = 0
    addi t0, x0, 8                          # counter = 8 = mant_b 8-bit

SHIFT_LOOP:
    andi t1, t6, 1                          # t1 = mant_b & 1
    beq  t1, x0, NO_ADD                     # if (mant_b & 1) == 0, skip add
    add  a4, a4, t5                         # result_mant += mant_a

NO_ADD:
    slli t5, t5, 1                          # mant_a <<= 1
    srli t6, t6, 1                          # mant_b >>= 1
    addi t0, t0, -1                         # counter--
    bne  t0, x0, SHIFT_LOOP                 # loop until counter = 0
    add  a3, a3, t3                         
    add  a3, a3, t4                         # result_exp = exp_a + exp_b + exp_adjust
    addi a3, a3, -BF16_EXP_BIAS             # result_exp -= 127
    li   t0, BF16_SIGN_MASK
    and  t0, t0, a4                         # t0 = result_mant & 0x8000
    bne  t0, x0, 1f
    srli a4, a4, 7                          # result_mant >>= 7
    andi a4, a4, 0x7F                       # result_mant &= 0x7F
    jal  x0, 2f

1:
    srli a4, a4, 8                          # result_mant >>= 8
    andi a4, a4, 0x7F                       # result_mant &= 0x7F
    addi a3, a3, 1                          # result_exp++
    
2:
    addi t0, x0, 0xFF
    beq  a3, t0, RETURN_INF                 # if result_exp == 0xFF, go to RETURN_INF
    bgt  a3, t0, RETURN_INF                 # if result_exp > 0xFF, go to RETURN_INF
    
3:
    beq  a3, x0, 4f                         # if result_exp == 0, go to 4
    blt  a3, x0, 4f                         # if result_exp < 0, go to 4
    jal  x0, RETURN_MUL

4:
    addi a0, x0, -6                         # a0 = -6
    blt  a3, a0, RETURN_ZERO_SIGN           # if result_exp < -6, go to RETURN_ZERO_SIGN
    addi a3, x0, 0                          # result_exp = 0
    addi t0, x0, 1
    sub  t0, t0, a3                         # t0 = 1 - result_exp
    srl  a4, a4, t0                         # result_mant >>= (1 - result_exp)

RETURN_INF:                                 #return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    slli a0, a2, 15
    li   t0, BF16_EXP_MASK
    or   a0, a0, t0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

RETURN_MUL:                                 
    slli a0, a2, 15                         # a0 = result_sign << 15
    andi t0, a3, 0xFF
    slli t0, t0, 7
    or   a0, a0, t0                         # a0 = (result_sign << 15) | (result_exp << 7)
    andi t0, a4, 0x7F
    or   a0, a0, t0                         # a0 = (result_sign << 15) | (result_exp << 7) | result_mant
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

#////////////////////////////////////////////   
#
#   BF16_DIV function
#
#   input: a0 = a (dividend), a1 = b (divisor)
#   return: a0 = a / b
#
#////////////////////////////////////////////
BF16_DIV:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   a1, 4(sp)                          # 4(sp) = b
    sw   a0, 0(sp)                          # 0(sp) = a                    

    srli t1, a0, 15                         # t1 = sign_a
    srli t2, a1, 15                         # t2 = sign_b
    srli t3, a0, 7
    srli t4, a1, 7
    andi t3, t3, 0xFF                       # t3 = exp_a
    andi t4, t4, 0xFF                       # t4 = exp_b
    andi t5, a0, 0x7F                       # t5 = mant_a
    andi t6, a1, 0x7F                       # t6 = mant_b
    xor  a2, t1, t2                         # a2 = result_sign = sign_a ^ sign_b

    addi t0, x0, 0xFF
    beq  t4, t0, 1f                         # if exp_b == 0xFF, go to 1
    beq  t4, x0, 3f                         # if exp_b == 0, go to 3

8:
    beq  t3, t0, 6f                         # if exp_a == 0xFF, go to 6
    beq  t3, x0, 7f                         # if exp_a == 0, go to 7
    jal  x0, CONT_DIV

1:
    bne  t6, x0, RETURN_B                   # if mant_b != 0, go to RETURN_B
    beq  t3, t0, 2f                         # if exp_a == 0xFF, go to 2
    jal  x0, RETURN_ZERO_SIGN               # return 0

2:
    bne  t5, x0, RETURN_NAN                 # if mant_a != 0, go to RETURN_NAN
    jal  x0, RETURN_ZERO_SIGN               # return 0

3: 
    beq  t6, x0, 4f                         # if mant_b == 0, go to 4
    jal  x0, 8b                             # go to 8

4: 
    beq  t3, x0, 5f                         # if exp_a == 0, go to 5
    jal  x0, RETURN_INF                     # return inf

5:
    beq  t5, x0, RETURN_NAN                 # if mant_a == 0, go to return_nan
    jal  x0, RETURN_INF                     # return inf

6:
    bne  t5, x0, RETURN_A                   # if mant_a != 0, go to RETURN_A
    jal  x0, RETURN_INF                     # return inf

7:
    beq  t5, x0, RETURN_ZERO_SIGN           # if mant_a == 0, go to RETURN_ZERO_SIGN


CONT_DIV:
    bne  t3, x0, 1f                         # if exp_a != 0, go to 1
3:
    bne  t4, x0, 2f                         # if exp_b != 0, go to 2
    jal  x0, DIV_SHIFT

1:
    ori  t5, t5, 0x80                       # mant_a = mant_a | 0x80
    jal  x0, 3b

2:  
    ori  t6, t6, 0x80                       # mant_b = mant_b | 0x80

DIV_SHIFT:
    slli t1, t5, 15                         # t1 = dividend = mant_a << 15
    addi t5, t6, 0                          # t5 = divisor = mant_b
    addi t6, x0, 0                          # t6 = quotient = 0                     
    addi t0, x0, 0                          # t0 = i = 0

DIV_LOOP:
    addi t2, x0, 16
    beq  t0, t2, DIV_END
    slli t6, t6, 1                          # quotient <<= 1
    addi t2, x0, 15
    sub  t2, t2, t0                         # t2 = 15 - i
    sll  t3, t5, t2                         # t3 = divisor << (15 - i)
    blt  t1, t3, DIV_SKIP
    sub  t1, t1, t3                         # dividend -= (divisor << (15 - i))
    ori  t6, t6, 1                          # quotient |= 1

DIV_SKIP:
    addi t0, t0, 1
    jal  x0, DIV_LOOP

DIV_END:
    srli t3, a0, 7
    andi t3, t3, 0xFF                       # t3 = exp_a
    sub  a3, t3, t4                         # a3 = exp_a - exp_b
    addi a3, a3, BF16_EXP_BIAS             # a3 = result_exp = exp_a - exp_b + 127
    beq  t3, x0, 1f                         # if exp_a == 0, go to 1

2: 
    beq  t4, x0, 3f                         # if exp_b == 0, go to 3
    jal  x0, DIV_EXP_DONE

1:
    addi a3, a3, -1                         # result_exp--
    jal x0, 2b                              # go to 2  

3:
    addi a3, a3, 1                          # result_exp++

DIV_EXP_DONE:
    li   t0, BF16_SIGN_MASK
    and  t1, t6, t0                         # quotient & 0x8000
    bne  t1, x0, DIV_SHIFT_DONE
3:
    beq  t6, x0, 1f
    jal  x0, DIV_SHIFT_DONE

1:
    addi t1, x0, 1                          # t1 = 1
    bgt  a3, t1, 2f                         # if result_exp > 1, go to 2
    jal  x0, DIV_SHIFT_DONE

2:
    slli t6, t6, 1                          # quotient <<= 1
    addi a3, a3, -1                         # result_exp--
    jal  x0, 3b

DIV_SHIFT_DONE:
    srli t6, t6, 8                          # quotient >>= 8
    andi t6, t6, 0x7F                       # t6 = result_mant = quotient & 0x7F
    addi t0, x0, 0xFF
    beq  a3, t0, RETURN_INF                 # if result_exp == 0xFF, go to RETURN_INF
    bgt  a3, t0, RETURN_INF                 # if result_exp > 0xFF, go to RETURN_INF
    beq  a3, x0, RETURN_ZERO_SIGN           # if result_exp == 0, go to RETURN_ZERO_SIGN
    blt  a3, x0, RETURN_ZERO_SIGN           # if result_exp < 0, go to RETURN_ZERO_SIGN

RETURN_DIV:
    slli a0, a2, 15                         # a0 = result_sign << 15
    andi t0, a3, 0xFF
    slli t0, t0, 7
    or   a0, a0, t0                         # a0 = (result_sign << 15) | (result_exp << 7)
    andi t0, t6, 0x7F                       # t0 = result_mant = quotient & 0x7F
    or   a0, a0, t0                         # a0 = (result_sign << 15) | (result_exp << 7) | result_mant
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

#////////////////////////////////////////////   
#
#   BF16_SQRT function
#
#   input: a0(old), return: a0(result)
#
#////////////////////////////////////////////
BF16_SQRT:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)                          # 0(sp) = a
    srli t1, a0, 15                         # t1 = sign
    srli t2, a0, 7                          # t2 = exp
    andi t2, t2, 0xFF                       # t2 = exp
    andi t3, a0, 0x7F                       # t3 = mant

    addi t0, x0, 0xFF
    beq  t2, t0, 1f                         # if exp == 0xFF, go to 1
    jal  x0, 2f

1: 
    bne  t3, x0, RETURN_A_SQRT              # if mant != 0, go to RETURN_A
    bne  t1, x0, RETURN_NAN_SQRT            # if sign != 0, go to RETURN_NAN
    jal  x0, RETURN_A_SQRT                  # else return a

2: 
    beq  t2, x0, 3f                         # if exp == 0, go to 3
    jal  x0, 4f
3:  
    beq  t1, x0, RETURN_ZERO_SQRT           # if sign == 0, go to RETURN_ZERO_SQRT

4:  
    bne  t1, x0, RETURN_NAN_SQRT            # if sign != 0, go to RETURN_NAN_SQRT
    beq  t2, x0, RETURN_ZERO_SQRT           # if exp == 0, go to RETURN_ZERO_SQRT

    addi t0, x0, BF16_EXP_BIAS
    sub  t2, t2, t0                         # t2 = e = exp - 127
    ori  t3, t3, 0x80                       # t3 = m = mant | 0x80
    andi t4, t2, 1                          # t4 = e & 1
    bne  t4, x0, 1f                         # if (e & 1) != 0, go to 1
    jal  x0, 2f                             # else go to 2
1: 
    slli t3, t3, 1                          # t3 = m = mant << 1
    addi t2, t2, -1                         # e = e - 1
    srli t2, t2, 1                          # e = e >> 1
    addi t2, t2, BF16_EXP_BIAS              # t2 = new_exp = e + 127
    jal  x0, ADJUST_DONE
2:  
    srli t2, t2, 1                          # e = e >> 1
    addi t2, t2, BF16_EXP_BIAS              # t2 = new_exp = e + 127

ADJUST_DONE:
    # t3 = m, t2 = new_exp, t1 = sign
    addi t0, x0, 90                         # low
    addi t1, x0, 256                        # high
    addi a2, x0, 128                        # result

BS_LOOP:
    bgt  t0, t1, BS_END
    add  t4, t0, t1
    srli t4, t4, 1                          # t4 = mid
    mv   a3, t4                             # a3 = mid  

    addi a0, x0, 0                          # acc = 0
    mv   t6, a3                             # multiplicand = mid
    mv   t5, a3                             # multiplier   = mid
    addi a1, x0, 9                          # counter = 9

BS_MUL_LOOP:
    andi t4, t5, 1                          # t4 = (multiplier & 1)
    beq  t4, x0, BS_NO_ADD
    add  a0, a0, t6

BS_NO_ADD:
    slli t6, t6, 1
    srli t5, t5, 1
    addi a1, a1, -1
    bne  a1, x0, BS_MUL_LOOP

    srli a0, a0, 7                          # sq

BS_UPDATE:
    bgeu t3, a0, BS_IF
    j    BS_ELSE

BS_IF:
    mv   a2, a3                             # result = mid 
    addi t0, a3, 1                          # low = mid + 1
    j    BS_LOOP

BS_ELSE:
    addi t1, a3, -1                         # high = mid - 1
    j    BS_LOOP

BS_END:                                       
    addi a0, x0, 256
    bgeu a2, a0, 1f                         # if (result >= 256), go to 1
    addi a0, x0, 128
    addi a1, x0, 1
    blt  a2, a0, 2f                         # if (result < 128), go to 2
    jal  x0, 5f

1:
    srli a2, a2, 1                          # result >>= 1
    addi t2, t2, 1                          # new_exp++
    jal  x0, 5f

2:
    blt  a2, a0, 3f                         # if (result < 0), go to 3
    jal  x0, 5f

3:  bgt  t2, a1, 4f
    jal  x0, 5f

4:
    slli a2, a2, 1                          # result <<= 1
    addi t2, t2, -1                         # new_exp--
    jal  x0, 2b

5:
    andi t3, a2, 0x7F                       # result_mant = result & 0x7F
    addi a0, x0, 0xFF
    bge  t2, a0, RETURN_INF_SQRT            # if new_exp >= 0xFF, go to RETURN_INF
    blt  t2, x0, RETURN_ZERO_SQRT           # if new_exp < 0, go to RETURN_ZERO
    beq  t2, x0, RETURN_ZERO_SQRT           # if new_exp == 0, go to RETURN_ZERO
    andi t2, t2, 0xFF                       # new_exp = new_exp & 0xFF
    slli t2, t2, 7
    or   a0, t2, t3                         # a0 = (new_exp << 7) | result_mant
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

RETURN_INF_SQRT:                            #return (bf16_t) {.bits = (sign << 15) | 0x7F80};
    li   a0, BF16_EXP_MASK
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

RETURN_A_SQRT:
    lw   a0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

RETURN_NAN_SQRT:
    li   a0, 0x7FC0
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

RETURN_ZERO_SQRT:
    addi a0, x0, 0
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

#////////////////////////////////////////////   
#
#   BF16_Equal function
#
#   input: a0 = a, a1 = b, return 1 if a == b else 0
#
#////////////////////////////////////////////
BF16_EQ: # a0 = a, a1 = b, a0 return 1 if a == b else 0
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

1:
    addi a0, x0, 0                          # Not Equal return 0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

2:
    addi a0, x0, 1                          # Equal return 1
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

3:
    lw   a0, 0(sp)                          # load a
    lw   a1, 4(sp)                          # load b
    beq  a0, a1, 2b                         # if a == b, go to Equal
    jal  x0, 1b                             # else go to Not Equal

#////////////////////////////////////////////   
#
#   BF16_Less_Than function
#
#   input: a0 = a, a1 = b, return 1 if a < b else 0
#
#////////////////////////////////////////////
BF16_LT:
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

1:
    addi a0, x0, 0                          # Not Less return 0
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

2:
    addi a0, x0, 1                          # Less return 1
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

3:
    lw   a0, 0(sp)                          # load a
    lw   a1, 4(sp)                          # load b
    srli  t0, a0, 15                        # t0 = sign_a
    srli  t1, a1, 15                        # t1 = sign_b
    bne  t0, t1, 4f                         # if sign_a != sign_b, go to sign bit compare
    jal  x0, 5f                             # if sign_a == sign_b

4: 
    bgt  t0, t1, 2b                         # if sign_a > sign_b, go to Less
    jal  x0, 1b                             # else go to Not Less

5: 
    beq  t0, x0, 7f                         # if a_sign == 0, go to both pos
    jal  x0, 6f                             # if a_sign == 1, go to both neg

6: 
    bgt  a0, a1, 2b                         # if a > b, go to Less
    jal  x0, 1b                             # else go to Not Less

7: 
    blt  a0, a1, 2b                         # if a < b, go to Less
    jal  x0, 1b                             # else go to Not Less


#////////////////////////////////////////////   
#
#   BF16_Greater_Than function
#
#   input: a0 = a, a1 = b, return 1 if a > b else 0
#
#////////////////////////////////////////////
BF16_GT: # a0 = a, a1 = b, a0 return 1 if a > b else 0
    mv   t0, a0
    mv   a0, a1
    mv   a1, t0
    jal  x0, BF16_LT

#////////////////////////////////////////////   
#
#   F32_TO_BF16 function
#
#   input: a0 = f32 bits, return bf16 bits in a0
#
#////////////////////////////////////////////
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
    li   t1, BF16_ALL_MASK                  # t1 = 0x7FFF
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

#////////////////////////////////////////////   
#
#   BF16_TO_F32 function
#
#   input: a0 = bf16 bits, return f32 bits in a0
#
#////////////////////////////////////////////
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
    la   s1, arithmeticValues_a
    la   s2, arithmeticValues_b
    la   s3, arithmeticResults

    lw   a0, 0(s2)                         
    jal  ra, F32_TO_BF16
    mv   a1, a0                             # a1 = bf16 of b
    lw   a0, 0(s1)                         
    jal  ra, F32_TO_BF16                    # a0 = bf16 of a
    jal  ra, BF16_ADD                       # a0 = a + b
    jal  ra, BF16_TO_F32
    lw   t0, 0(s3)                          # t0 = arithmeticResults[]
    bne  a0, t0, ARITHMETIC_FAIL

    lw   a0, 4(s2)
    jal  ra, F32_TO_BF16
    mv   a1, a0                             # a1 = bf16 of b
    lw   a0, 4(s1)
    jal  ra, F32_TO_BF16                    # a0 = bf16 of a
    jal  ra, BF16_SUB                       # a0 = a - b
    jal  ra, BF16_TO_F32
    lw   t0, 4(s3)                          # t0 = arithmeticResults[]
    bne  a0, t0, ARITHMETIC_FAIL

    lw   a0, 8(s2)
    jal  ra, F32_TO_BF16
    mv   a1, a0                             # a1 = bf16 of b
    lw   a0, 8(s1)
    jal  ra, F32_TO_BF16                    # a0 = bf16 of a
    jal  ra, BF16_MUL                       # a0 = a * b
    jal  ra, BF16_TO_F32
    lw   t0, 8(s3)                          # t0 = arithmeticResults[]
    bne  a0, t0, ARITHMETIC_FAIL

    lw   a0, 12(s2)
    jal  ra, F32_TO_BF16
    mv   a1, a0                             # a1 = bf16 of b
    lw   a0, 12(s1)
    jal  ra, F32_TO_BF16                    # a0 = bf16 of
    jal  ra, BF16_DIV                       # a0 = a / b
    jal  ra, BF16_TO_F32
    lw   t0, 12(s3)                         # t0 = arithmeticResults[]
    bne  a0, t0, ARITHMETIC_FAIL

    lw   a0, 16(s1)
    jal  ra, F32_TO_BF16                    # a0 = bf16 of a
    jal  ra, BF16_SQRT                      # a0 = sqrt(a)
    jal  ra, BF16_TO_F32
    lw   t0, 16(s3)                         # t0 = arithmeticResults[]
    bne  a0, t0, ARITHMETIC_FAIL

    lw   a0, 20(s1)
    jal  ra, F32_TO_BF16                    # a0 = bf16 of a
    jal  ra, BF16_SQRT                      # a0 = sqrt(a)
    jal  ra, BF16_TO_F32
    lw   t0, 20(s3)                         # t0 = arithmeticResults[]
    bne  a0, t0, ARITHMETIC_FAIL

    jal  x0, ARITHMETIC_ALL_PASS

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

EDGE_CASE_TEST:
    addi sp, sp, -4
    sw   ra, 0(sp)
    addi s0, x0, 0
    la   s1, edge_caseValues
    la   s2, edge_caseResults

    lw   a0, 0(s1)
    jal  ra, F32_TO_BF16
    lw   t0, 0(s2)
    bne  a0, t0, EDGE_CASE_TEST_FAIL

    lw   a0, 4(s1)
    jal  ra, F32_TO_BF16
    mv   a1, a0
    li   a0, 0x41200000
    jal  ra, F32_TO_BF16
    jal  ra, BF16_MUL
    jal  ra, BF16_TO_F32
    lw   t0, 4(s2)
    bne  a0, t0, EDGE_CASE_TEST_FAIL

    li   a0, 0x501502F9
    jal  ra, F32_TO_BF16
    mv   a1, a0
    lw   a0, 8(s1)
    jal  ra, F32_TO_BF16
    jal  ra, BF16_DIV
    jal  ra, BF16_TO_F32
    lw   t0, 8(s2)
    bne  a0, t0, EDGE_CASE_TEST_FAIL
    jal  x0, EDGE_CASE_ALL_PASS

EDGE_CASE_TEST_FAIL:
    la   a0, edge_caseFAILmsg
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

EDGE_CASE_ALL_PASS:    
    la   a0, edge_caseOKmsg
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
    beq  s0, s3, ROUNDING_ALL_PASS  
    slli s4, s0, 2             
    add  s5, s1, s4                      
    add  s6, s2, s4                      
    lw   a0, 0(s5)                      
    lw   s7, 0(s6)                        
    jal  ra, F32_TO_BF16 
    jal  ra, BF16_TO_F32
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