.data
    TEST_DATA:   .word  0, 1, 2, 3, 4,
                 .word  7, 8, 14, 15, 16,
                 .word  31, 32, 63, 64, 123,
                 .word  255, 256, 1023, 1024, 0xFFFFFFFF  
    
    TEST_RESULT: .word  0, 1, 2, 3, 3, 
                 .word  5, 4, 6, 7, 5, 
                 .word  9, 6, 11, 7, 12, 
                 .word  15, 9, 19, 11, 63
    
    TEST_OK_MSG: .string "All test cases passed!\n"
    
    TEST_FAIL_MSG: .string "Test case failed!\n"
.text

main:
    jal  ra, TEST
    li  a7, 10
    ecall


#////////////////////////////////////////////
#
#   TEST Function
#
#////////////////////////////////////////////
TEST:
    addi sp, sp, 4
    sw   ra, 0(sp)                          # save return address
    la   s0, TEST_DATA
    la   s1, TEST_RESULT    
    li   s2, 20                              # number of test cases
    li   s3, 0                              # current test case index

TEST_LOOP:
    beq  s3, s2, TEST_ALL_PASSED            # if (i == number of test cases) all passed
    lw   a0, 0(s0)                          # load test data
    jal  ra, NUMBEROFSTEPS                  # call numberOfSteps
    lw   t0, 0(s1)                          # load expected result
    bne  a0, t0, TEST_FAIL                  # if (result != expected) fail
    addi s0, s0, 4                          # move to next test data
    addi s1, s1, 4                          # move to next expected result
    addi s3, s3, 1                          # i++
    jal  x0, TEST_LOOP

TEST_ALL_PASSED:
    la   a0, TEST_OK_MSG
    li   a7, 4
    ecall
    lw   ra, 0(sp)                          # restore return address
    addi sp, sp, 4
    ret

TEST_FAIL:
    la   a0, TEST_FAIL_MSG
    li   a7, 4
    ecall
    lw   ra, 0(sp)                          # restore return address
    addi sp, sp, 4
    ret

#////////////////////////////////////////////
#
#   numberOfSteps Function
#
#   input: a0 = num, output: a0 = steps
#
#////////////////////////////////////////////
NUMBEROFSTEPS:
    addi sp, sp, -4
    sw   ra, 0(sp)                          # save return address
    beqz a0, RETURN_ZERO
    jal  ra, CLZ                            # a0 = original num, a1 = clz_result
    addi a2, x0, 32
    sub  a1, a2, a1                         # a1 = 32 - clz(num)
    jal  ra, POPCOUNT                       # a0 = popcount(num)
    add  a0, a0, a1                         # steps = popcount(num) + (32 - clz(num))
    addi a0, a0, -1                         # steps -= 1                      
    lw   ra, 0(sp)                          # restore return address
    addi sp, sp, 4
    ret

RETURN_ZERO:
    lw   ra, 0(sp)                          # restore return address
    addi sp, sp, 4
    addi a0, x0, 0                          # steps = 0
    ret

#////////////////////////////////////////////
#
#   CLZ Function
#
#   input a0 = x, output a0 = orig x, a1 = clz_result
#
#////////////////////////////////////////////
CLZ:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   a0, 4(sp)         
    addi t0, x0, 32                         # n = 32
    addi t1, x0, 16                         # c = 16

CLZ_LOOP:
    srl  t2, a0, t1                         # t2 = x >> c
    beq  t2, x0, CLZ_LOWER                  # if(t2 == 0) goto lower
    sub  t0, t0, t1                         # n -= c
    mv   a0, t2                             # x = y

CLZ_LOWER:
    srli t1, t1, 1
    bne  t1, x0, CLZ_LOOP
    sub  a1, t0, a0                         # return = n - x
    lw   ra, 0(sp)
    lw   a0, 4(sp)           
    addi sp, sp, 8
    ret

#////////////////////////////////////////////
#
#   POPCOUNT Function
#
#   input a0 = x, output a0 = popcount result
#
#////////////////////////////////////////////
POPCOUNT:               
    li   t1, 0x55555555                     # t1 = 0x55555555
    and  t2, a0, t1                         # t2 = u & 0x55555555
    srli t3, a0, 1                          # t3 = u >> 1
    and  t3, t3, t1                         # t3 = (u >> 1) & 0x55555555
    add  a0, t2, t3                         # u = (u & 0x55555555) + ((u >> 1) & 0x55555555)

    li   t1, 0x33333333                     # t1 = 0x33333333
    and  t2, a0, t1                         # t2 = u & 0x33333333
    srli t3, a0, 2                          # t3 = u >> 2
    and  t3, t3, t1                         # t3 = (u >> 2) & 0x33333333
    add  a0, t2, t3                         # u = (u & 0x33333333) + ((u >> 2) & 0x33333333)

    li   t1, 0x0F0F0F0F                     # t1 = 0x0F0F0F0F
    and t2, a0, t1                          # t2 = u & 0x0F0F0F0F
    srli t3, a0, 4                          # t3 = u >> 4
    and t3, t3, t1                          # t3 = (u >> 4) & 0x0F0F0F
    add a0, t2, t3                          # u = (u & 0x0F0F0F0F) + ((u >> 4) & 0x0F0F0F0F)

    li   t1, 0x00FF00FF                     # t1 = 0x00FF00FF
    and  t2, a0, t1                         # t2 = u & 0x00FF00FF
    srli t3, a0, 8                          # t3 = u >> 8
    and  t3, t3, t1                         # t3 = (u >> 8) & 0x00FF00FF
    add  a0, t2, t3                         # u = (u & 0x00FF00FF) + ((u >> 8) & 0x00FF00FF)    

    li   t1, 0x0000FFFF                     # t1 = 0x0000FFFF
    and  t2, a0, t1                         # t2 = u & 0x0000FFFF
    srli t3, a0, 16                         # t3 = u >> 16
    and  t3, t3, t1                         # t3 = (u >> 16) & 0x0000FFFF
    add  a0, t2, t3                         # u = (u & 0x0000FFFF) + ((u >> 16) & 0x0000FFFF)
    
    ret