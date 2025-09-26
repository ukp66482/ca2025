.data
    newline: .string "\n"
    
    convertOKmsg: .string "Basic conversions: PASS\n"
    convertFAILmsg: .string "Basic conversions: FAIL\n"
    
    convert_FP32: .word 0x00000000, 0x3F800000, 0xBF800000, 0x40000000 
                  .word 0xC0000000, 0x3F000000, 0xBF000000, 0x40490FD0
                  .word 0xC0490FD0, 0x501502F9, 0xD01502F9 
    
    convert_BF16: .word 0x0000, 0x3F80, 0xBF80, 0x4000
                  .word 0xC000, 0x3F00, 0xBF00, 0x4049
                  .word 0xC049, 0x5015, 0xD015

    converted_FP32: .word 0x00000000, 0x3F800000, 0xBF800000, 0x40000000
                    .word 0xC0000000, 0x3F000000, 0xBF000000, 0x40490000
                    .word 0xC0490000, 0x50150000, 0xD0150000
.text
main:
    jal ra, CONVERT_TEST
    li   a7, 10
    ecall

F32_TO_BF16:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)
    srli t0, a0, 23              # t0 = exponent + mantissa
    andi t0, t0, 0xFF            # t0 = exponent + 0x7F
    addi t1, x0, 0xFF            # t1 = 0xFF
    beq  t0, t1, F32_TO_BF16_INF_NAN         # if exponent == 0xFF, go to INF_NAN

    srli t0, a0, 16            # t0 = f32bits >> 16
    andi t0, t0, 1             # t0 = (f32bits >> 16) & 1 = tmp
    add a0, a0, t0            # a0 = f32bits + tmp
    li t1, 0x7FFF            # t1 = 0x7FFF
    add a0, a0, t1            # a0 = f32bits + tmp + 0x7FFF
    srli a0, a0, 16            # a0 = f32bits >> 16
    lw ra, 4(sp)             
    addi sp, sp, 8
    ret

F32_TO_BF16_INF_NAN:
    srli a0, a0, 16            # a0 = f32bits >> 16
    lw ra, 4(sp)
    addi sp, sp, 8
    ret   

BF16_TO_F32:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)
    slli a0, a0, 16            # a0 = bf16 << 16       
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

CONVERT_TEST:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi s0, x0, 0
    la s1, convert_FP32
    la s2, convert_BF16
    la s3, converted_FP32
    li s4, 11

CONVERT_TEST_LOOP:
    beq s0, s4, CONVERT_ALL_PASS        # if i == 11, all pass

    slli s5, s0, 2                      # s5 = i * 4
    add s6, s1, s5                      # s6 = &convert_FP32[i]
    lw a0, 0(s6)                        # a0 = convert_FP32[i]
    jal ra, F32_TO_BF16                          

    slli s5, s0, 2                      # s5 = i * 4
    add s6, s2, s5                      # s6 = &convert_BF16[i] 
    lhu t0, 0(s6)                        # t0 = convert_BF16[i]
    bne a0, t0, CONVERT_FAIL

    jal ra, BF16_TO_F32
    slli s5, s0, 2                      # s5 = i * 4
    add s6, s3, s5
    lw t0, 0(s6)
    bne a0, t0, CONVERT_FAIL

    addi s0, s0, 1
    jal x0, CONVERT_TEST_LOOP

CONVERT_FAIL:
    la a0, convertFAILmsg
    li a7, 4
    ecall
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

CONVERT_ALL_PASS:
    la a0, convertOKmsg
    li a7, 4
    ecall
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
