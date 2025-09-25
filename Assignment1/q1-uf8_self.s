.data
newline: .string "\n"
input: .word 0x00F00000
.text
main:
    la a0, input
    lw a0, 0(a0)
    jal ra, CLZ
    li a7 1
    ecall
    li a7 10
    ecall

CLZ:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp) # input x
    addi t0, x0, 32 # t0 = n    
    addi t1, x0, 16 # t1 = c

CLZ_LOOP:
    srl t2, a0, t1 # t2 = x >> c = y
    beq t2, x0, CLZ_MSB_IN_LOWER_HALF   #if y==0
    sub t0, t0, t1 # n = n - c
    add a0, t2, x0 # x = y

CLZ_MSB_IN_LOWER_HALF:
    srli t1, t1, 1
    bne t1, x0, CLZ_LOOP
    sub a0, t0, a0
    lw ra, 4(sp)
    lw a1, 0(sp) //input x 
    addi sp, sp, 8
    ret //a0 clz_result
