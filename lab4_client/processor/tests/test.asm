addi $1, $0, 0x5555 # $1 = 0x5555
j skip

addi $1, $0, 0xDEAD
addi $2, $0, 0xDEAD
addi $3, $0, 0xDEAD
addi $4, $0, 0xDEAD
addi $5, $0, 0xDEAD
addi $6, $0, 0xDEAD
addi $7, $0, 0xDEAD
addi $8, $0, 0xDEAD
addi $9, $0, 0xDEAD
addi $10, $0, 0xDEAD

skip: ori $2, $1, 0xFFFF # $2 = 0xFFFF
andi $3, $1, 0xFFFF # $3 = 0x5555
xori $4, $3, 0xAAAA # $4 = 0xFFFF
slti $5, $0, 0x0FFF # $5 = 1

jal nothing

addi $6, $0, 0xFEED # $6 = 0xFEED
j continue
addi $30, $0, 0x000F # should be ignored

nothing: addi $30, $0, 0x000C # $30 = 0x000C
jr $31

continue: beq $2, $4, zero2

zero1: andi $1, $1, 0 # should be ignored
j next

zero2: andi $2, $2, 0 # $2 = 0

bne $0, $3, zero3
j ignore
zero3: andi $3, $3, 0 # $3 = 0
j next

ignore: addi $29, $0, 0xA000 # should be ignored

next: addi $20, $0, 0xEEEE # $20 = 0xEEEE

lw $1, 0($0) # load word at address 0x0 to $1 ($1 = 15)
andi $2, $2, 0 # $2 = 0x0000
addi $2, $0, 0xAAAA # $2 = 0xAAAA
sw $2, 16($0) # store 0xAAAA at address 0x10