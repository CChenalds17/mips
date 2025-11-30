                addi    $s0, $zero, 0          # s0 = 0
                addi    $s1, $zero, 5          # s1 = 5
                addi    $s2, $zero, -3         # s2 = -3  (sign-extended)
                addi    $t0, $zero, 0xffff   # t0 = -1 (0xFFFF sign-extended)
                andi    $t0, $t0, 0x00ff     # t0 = 0x00FF (zero-extended)
                ori     $t1, $zero, 0xF0F0   # t1 = 0xF0F0
                xori    $t1, $t1, 0x0F0F     # t1 ^= 0x0F0F  -> 0xFFFF
                slti    $t2, $s2, 0            # t2 = (s2 < 0) ? 1 : 0  -> 1
                add     $s3, $s1, $s1          # s3 = 10
                sub     $s4, $s3, $s2          # s4 = 13  (10 - (-3))
                and     $s5, $s3, $t0          # s5 = s3 & 0x00FF
                or      $s6, $s4, $t1          # s6 = 13 | 0xFFFF -> 0xFFFF
                xor     $s7, $s6, $t1          # s7 = 0xFFFF ^ 0xFFFF -> 0
                nor     $t3, $s7, $zero        # t3 = ~(0 | 0) -> 0xFFFFFFFF
                slt     $t4, $s2, $s1          # t4 = (-3 < 5) -> 1
                sll     $t5, $s1, 0            # t5 = s1 << 0 (no-op, exercises shamt=0)
                srl     $t6, $t3, 31           # t6 = 0xFFFFFFFF >> 31 -> 1 (logical)
                sra     $t7, $s2, 31           # t7 = (-3) >> 31 -> 0xFFFF_FFFF (arith)
                addi    $8,  $0,   123         # $t0 = 123   using $8
                addi    $9,  $0,   45          # $t1 = 45    using $9
                add     $10, $9,   $8          # $t2 = t1 + t0 (using $10)
                addi    $sp, $sp, -32          # make some space
                sw      $s3, 0($sp)            # store s3
                sw      $s4, 4($sp)            # store s4
                sw      $s5, 8($sp)            # store s5
                sw      $s6, 12($sp)           # store s6
                sw      $t2, 16($sp)           # store t2
                lw      $k0, 12($sp)           # k0 = s6
                lw      $k1, 0($sp)            # k1 = s3
                lw      $ra, 16($sp)           # ra = t2
                lw      $v0, 8($sp)            # v0 = s5
                lw      $v1, 4($sp)            # v1 = s4
                addi    $sp, $sp, -8
                sw      $v0, 0($sp)            # push v0/v1 again at negative offset later
                sw      $v1, 4($sp)
                beq     $t4, $zero, skip1      # should not branch (t4==1)
                addi    $s0, $s0, 1            # fall-through increments s0
skip1:          bne     $s0, $s0, after_skip1  # never taken; tests zero offset encoding
after_skip1:    nop                            # branch delay slot not modeled; still encode NOP
loop:           addi    $t8, $t8, 1            # t8++
                bne     $t8, $s1, loop         # loop until t8 == 5
                nop
                j       middle                 # absolute jump forward
                nop
middle:         jal     func                   # call function (synthesizes $ra)
                addi    $s0, $s0, 1            # executed after returning
                j       end
                nop
func:           ori     $t9, $zero, 0x1234
                xori    $t9, $t9,   0x00FF    # t9 ^= 0x00FF
                add     $a0, $t9,  $k0          # mix values
                lw      $v0, 0x0($sp)           # v0 from stack (hex imm syntax)
                lw      $v1, 0x4($sp)           # v1 from stack
                add     $a1, $v0,  $v1
                addi    $sp, $sp, 8             # pop those two
                jr      $ra                     # return
                nop
end:            addi    $gp, $zero, 0xBEEF    # just something fun
                sw      $gp, -8($sp)            # negative offset form
                lw      $fp, -8($sp)
                nop                             # final NOP
