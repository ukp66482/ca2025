.data
newline: .string "\n"
input: .word 0
.text
main:
    la a0, input
    lw a0, 0(a0)
    #jal ra, CLZ
    jal ra, UF8_DECODE
    li a7 1
    ecall
    li a7 10
    ecall

CLZ:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)                        # input x
    addi t0, x0, 32                     # t0 = n    
    addi t1, x0, 16                     # t1 = c

CLZ_LOOP:
    srl t2, a0, t1                      # t2 = x >> c = y
    beq t2, x0, CLZ_MSB_IN_LOWER_HALF   #if y==0
    sub t0, t0, t1                      # n = n - c
    add a0, t2, x0                      # x = y

CLZ_MSB_IN_LOWER_HALF:
    srli t1, t1, 1
    bne t1, x0, CLZ_LOOP
    sub a0, t0, a0                      # return
    lw ra, 4(sp)
    lw a1, 0(sp)                        # input x 
    addi sp, sp, 8
    ret                                 # a0 clz_result, a1 input

UF8_DECODE:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)
    andi t0, a0, 0x0f                   # t0 = mantissa
    srli t1, a0, 4                      # t1 = exponent 
    addi t2  x0, 15       
    sub  t2, t2, t1                     # t2 = 15 - exponent
    lui  t3, 0x8                        # 0x8 << 12 = 0x8000 upper 20 bits
    addi t3, t3, -1                     # 0x8000 - 1 = 0x7FFF
    srl  t3, t3, t2                     # t3 = 0x7FFF >> (15 - exponent)
    slli t3, t3, 4                      # t3 = t3 << 4  (offset)
    sll  t0, t0, t1
    add  t0, t0, t3
    addi a0, t0, 0    
    lw ra, 4(sp)
    lw a1, 0(sp) 
    addi sp, sp, 8
    ret                                 # a0 decode_result, a1 input