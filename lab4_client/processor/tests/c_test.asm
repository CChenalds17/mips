# I-Type Instructions
    addi    $s0, $0, 5          # $s0 = 0 + 5
    addi    $s1, $0, 2          # $s1 = 0 + 2
    addi    $t0, $0, 100        # $t0 = 0 + 100

# R-Type Instructions
    sra     $s3, $t0, 1         # Shift right arithmetic $t0 by 1 bits and store in $s3 (50)
    srl     $s2, $s3, 2         # Shift right logical $s3 by 2 bits and store in $s2 (12)
    sll     $t1, $t0, 4         # Shift left logical $t0 by 4 bits and store in $t1 (1600)
    nor     $s4, $s2, $s3       # nor operation between $s2, $s3 and store in $s4 (4294967233, 11111111111111111111111111000001)
    xor     $s5, $s2, $t1       # xor operation between $s2, $t1 and store in $s5 (1612, 11001001100)
    or      $s6, $s4, $s5       # or operation between $s4, $s5 and store in $s6 (4294967245, 11111111111111111111111111001101)
    and     $t2, $t0, $t1       # and operation between $t0 and $t1 and store in $t2 (64, 00001000000)
    sub     $t3, $s0, $s1       # subtract $s1 from $s0 and store in $t3 (3)
    add     $t4, $s1, $t3       # add $s1 and $t3 and store in $t4 (5)
    slt     $s7, $t1, $t4       # if $t1 < $t4, $s7 = 1, else $s7 = 0 (0)
    nop                         # test nop

# I-types 
    andi    $s7, $0, 5          # and operation between $s0, 5 and store in $s7 (0)
    ori     $s6, $s7, 11        # or operation between $s7, 11 and store in $s6 (11)
    xori    $t4, $s3, 2         # xor operation between $s3, 2 and store in $t4 (48)
    slti    $t5, $s0, 1         # if $s0 < 1, $t5 = 1, else $t5 = 0 (0)

    sw      $s1, 4($t1)         # store word $s1 to address ($t1 + 4) (0x644  |  2)
    lw      $t2, 4($t1)         # load word from address ($t1 + 4) and store in $t2 (2)

# J-types and bne, beq
        addi    $s1, $0, 0       # i = 0
        addi    $t0, $0, 2       # $t0 = 2
loop:   beq     $t0, $s1, nloop  # if i == 2, exit loop
        addi    $s1, $s1, 1      # i = i + 1
        j loop                   # repeat
nloop:  bne     $t0, $s1, main   # if i != 2, go to main
        addi    $s1, $s1, 1      # i = 3
        j nloop                  # repeat

# s1 = 3, t0 = 2

main:   addi $a0, $0, 10             # argument 0 = 10
        addi $a1, $0, 3              # argument 1 = 3

# Fibonacci function
        addi $t8, $0, 0         # register t8 = 0
        addi $t9, $0, 1         # register t9 = 1
        addi $t7, $0, 8         # register t7 = 8 
        j fib 

fib:    add $s7, $t8, $t9       # register s7 = t8 + t9
        addi $t8, $t9, 0        # register t8 = t9
        addi $t9, $s7, 0        # register t9 = s7
        beq $s7, $t7, done      # if s7 == 8, jump to done
        j fib                   # recurse back to fib

# t7 = 8, t8 = 5, t9 = 8,
# s7 = 8

done:   nop
