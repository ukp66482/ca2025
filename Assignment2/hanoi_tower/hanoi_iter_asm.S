.text
#//////////////////////////////////////////////
#
#   hanoi_iter_asm
#   input : a0 = n (number of disks)
#   output: a0 = total moves = 2^n - 1
#
#//////////////////////////////////////////////
.globl  hanoi_iter_asm
.type   hanoi_iter_asm, %function

hanoi_iter_asm:
    addi    sp, sp, -16
    sw      s0, 0(sp)      # counter i
    sw      s1, 4(sp)      # total moves
    sw      s2, 8(sp)      # limit (2^n)
    sw      s3, 12(sp)

    li      t0, 1
    sll     s2, t0, a0     
    addi    s2, s2, -1     # s2 = 2^n - 1  (total moves)
    mv      s1, zero       # move counter = 0
    li      s0, 1          # current step = 1

loop_iter:
    bgt     s0, s2, done   # while (i <= 2^n - 1)

    # gray(n) = n XOR (n >> 1)
    srli    t1, s0, 1
    xor     t2, s0, t1     # gray(i)
    
    # gray(n-1)
    addi    t3, s0, -1
    srli    t4, t3, 1
    xor     t5, t3, t4     # gray(i-1)

    # diff = gray(i) ^ gray(i-1)
    xor     t6, t2, t5

    addi    s1, s1, 1      # move++

    addi    s0, s0, 1      # i++
    jal     zero, loop_iter

done:
    mv      a0, s1         # return move count

    lw      s0, 0(sp)
    lw      s1, 4(sp)
    lw      s2, 8(sp)
    lw      s3, 12(sp)
    addi    sp, sp, 16
    ret