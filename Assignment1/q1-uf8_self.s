.data
newline: .string "\n"
arrow:   .string " -> "
okmsg:   .string "All tests passed.\n"

.text
main:
    addi a3, x0, 0                      # i = 0
    addi a4, x0, 256                    # limit = 256
    addi s3, x0, 1                      # passed = true (1)

LOOP:
    bge  a3, a4, END                    # if i >= 256 stop

    mv   a0, a3                         # fl = i
    jal  ra, UF8_DECODE
    mv   s1, a0                         # value
    
    mv   a0, s1
    jal  ra, UF8_ENCODE
    mv   s2, a0                         # fl2
    
    bne  s2, a3, SET_FAIL               # if fl2 != i fail  

NEXT_ITER:
    addi a3, a3, 1
    jal  x0, LOOP

SET_FAIL:
    addi s3, x0, 0                      # passed = false
    addi a3, a4, 0                      # force break (i = limit)
    jal  x0, LOOP

END:
    beq  s3, x0, EXIT                   # if !passed skip message
    la   a0, okmsg                  
    li   a7, 4
    ecall

EXIT:
    li   a7, 10
    ecall   

CLZ:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)                        # input x
    addi t0, x0, 32                     # t0 = n    
    addi t1, x0, 16                     # t1 = c

CLZ_LOOP:
    srl t2, a0, t1                      # t2 = x >> c = y
    beq t2, x0, CLZ_MSB_IN_LOWER_HALF   # if y==0
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

UF8_ENCODE:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)
    addi t0, x0, 16
    blt a0, t0, ENCODE_RET               # if x < 16 return a0
    jal ra, CLZ
    addi t0, x0, 31
    sub t0, t0, a0                      # t0 = msb = 31 - clz_result
    lw a0, 0(sp)                        # reload a0 = value
    addi t1, x0, 0                      # t1 = exponent = 0
    addi t4, x0, 0                      # t4 = overflow = 0
    addi t3, x0, 5                      
    blt t0, t3, ENCODE_FIND_E           # if msb < 5 goto ENCODE_FIND
    addi t1, t0, -4                     # exponent = msb - 4 
    addi t3, x0, 15
    blt t1, t3, SKIP                    # if exponent < 15 goto SKIP
    addi t1, x0, 15                     # exponent = 15

SKIP:
    addi t5, x0, 0                      # t5 = e = 0
    lw a0, 0(sp)                        # reload a0 = value

ENCODE_CAL_OVERFLOW:
    bge  t5, t1, ENCODE_ADJUST          # if e >= exponent
    slli t4, t4, 1                      # overflow = overflow << 1
    addi t4, t4, 16                     # overflow = overflow + 16
    addi t5, t5, 1                      # e++
    jal  x0, ENCODE_CAL_OVERFLOW

ENCODE_ADJUST:
    bge x0, t1, ENCODE_FIND_E           # if 0 >= exponent
    bge a0, t4, ENCODE_FIND_E           # if value >= overflow
    addi t4, t4, -16                    # overflow = overflow - 16
    srli t4, t4, 1                      # overflow = overflow >> 1
    addi t1, t1, -1                     # exponent--
    jal  x0, ENCODE_ADJUST          

ENCODE_FIND_E:
    addi t3, x0, 15
    bge  t1, t3, ENCODE_COMBINE         # if exponent >= 15 break
    slli t6, t4, 1                      # t6 = next_overflow = overflow << 1
    addi t6, t6, 16                     # next_overflow += 16
    blt  a0, t6, ENCODE_COMBINE         # if value < next_overflow break
    addi t1, t1, 1                      # exponent++
    addi t4, t6, 0                      # overflow = next_overflow
    jal  x0, ENCODE_FIND_E

ENCODE_COMBINE:
    sub t2, a0, t4                      # t2 = value - overflow
    srl t2, t2, t1                      # t2 = mantissa = (value - overflow) >> exponent
    slli t1, t1, 4                      # t1 = exponent << 4
    or  a0, t1, t2

ENCODE_RET:
    lw ra, 4(sp)
    lw a1, 0(sp) 
    addi sp, sp, 8
    ret