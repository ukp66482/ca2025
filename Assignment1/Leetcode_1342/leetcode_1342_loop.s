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
    li   a7, 10
    ecall


#////////////////////////////////////////////
#
#   TEST Function
#
#////////////////////////////////////////////
TEST:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   s0, TEST_DATA
    la   s1, TEST_RESULT
    li   s2, 20      # number of test cases
    li   s3, 0       # i = 0

TEST_LOOP:
    beq  s3, s2, TEST_ALL_PASSED
    lw   a0, 0(s0)
    jal  ra, NUMBEROFSTEPS_SIMPLE
    lw   t0, 0(s1)
    bne  a0, t0, TEST_FAIL
    addi s0, s0, 4
    addi s1, s1, 4
    addi s3, s3, 1
    jal  x0, TEST_LOOP

TEST_ALL_PASSED:
    la   a0, TEST_OK_MSG
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

TEST_FAIL:
    la   a0, TEST_FAIL_MSG
    li   a7, 4
    ecall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


#////////////////////////////////////////////
#
#   NUMBEROFSTEPS_SIMPLE Function
#
#   input: a0 = num
#   output: a0 = steps
#
#   algorithm: 
#   while (num != 0) {
#       if (num % 2 == 0) num /= 2;
#       else num -= 1;
#       steps++;
#   }
#
#////////////////////////////////////////////
NUMBEROFSTEPS_SIMPLE:
    addi sp, sp, -4
    sw   ra, 0(sp)
    li   t0, 0              # steps = 0

WHILE_LOOP:
    beqz a0, DONE           # while(num != 0)
    andi t1, a0, 1          # check LSB (num % 2)
    beqz t1, EVEN
    addi a0, a0, -1         # num -= 1
    addi t0, t0, 1          # steps++
    jal  x0, WHILE_LOOP

EVEN:
    srli a0, a0, 1          # num /= 2
    addi t0, t0, 1          # steps++
    jal  x0, WHILE_LOOP

DONE:
    mv   a0, t0             # return steps
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret