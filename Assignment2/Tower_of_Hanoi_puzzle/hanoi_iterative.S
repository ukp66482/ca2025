.text
.globl  Hanoi_iterative_asm
.type   Hanoi_iterative_asm, %function
Hanoi_iterative_asm:
    addi    sp, sp, -32
    sw      s0,  0(sp)
    sw      s1,  4(sp)
    sw      s2,  8(sp)
    sw      s3, 12(sp)
    sw      s4, 16(sp)
    sw      s5, 20(sp)

    # initialize disk positions (3 disks at peg 0)
    sw      zero, 24(sp)   # disk0
    sw      zero, 28(sp)   # disk1
    sw      zero, 32(sp)   # disk2

    addi    s0, zero, 1    # gray index n = 1
    addi    s5, zero, 0    # move counter = 0

game_loop:
    # total moves for 3 disks = 2^3 = 8 steps
    addi    t0, zero, 8
    beq     s0, t0, finish_game

    # gray(n) = n XOR (n >> 1)
    srli    t0, s0, 1
    xor     t1, s0, t0

    # gray(n-1)
    addi    t2, s0, -1
    srli    t3, t2, 1
    xor     t2, t2, t3

    # which bit changed?
    xor     t0, t1, t2

    # determine disk index
    addi    s1, zero, 0
    andi    t1, t0, 1
    bne     t1, zero, disk_found

    addi    s1, zero, 1
    andi    t1, t0, 2
    bne     t1, zero, disk_found

    addi    s1, zero, 2

disk_found:
    # skip invalid multi-bit flip (should not happen)
    andi    t5, t0, 5
    addi    t6, zero, 5
    beq     t5, t6, pattern_match
    jal     zero, continue_move
pattern_match:
continue_move:

    # get disk position
    slli    t0, s1, 2
    addi    t0, t0, 24
    add     t0, sp, t0
    lw      s2, 0(t0)

    # decide next peg
    bne     s1, zero, handle_large
    addi    s3, s2, 2
    addi    t1, zero, 3
    blt     s3, t1, update
    sub     s3, s3, t1
    jal     zero, update

handle_large:
    lw      t1, 24(sp)
    addi    s3, zero, 3
    sub     s3, s3, s2
    sub     s3, s3, t1

update:
    # store new position
    slli    t0, s1, 2
    addi    t0, t0, 24
    add     t0, sp, t0
    sw      s3, 0(t0)

    # increment move counter
    addi    s5, s5, 1

    # next step
    addi    s0, s0, 1
    jal     zero, game_loop

finish_game:
    # return move count
    mv      a0, s5

    lw      s0,  0(sp)
    lw      s1,  4(sp)
    lw      s2,  8(sp)
    lw      s3, 12(sp)
    lw      s4, 16(sp)
    lw      s5, 20(sp)
    addi    sp, sp, 32

    ret