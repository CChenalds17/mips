#!/usr/bin/env python3
#
# Template for MIPS assembler.py
#
# Usage:
#    python3 assembler.py [asm file]
#    OR
#    python3 assembler.py [asm file] > out.mem
#
# Supports:
#   R-type: add, sub, and, or, xor, nor, slt, sll, srl, sra, jr, nop
#   I-type: addi, andi, ori, xori, slti, beq, bne, lw, sw
#   J-type: j, jal
#
# Notes:
#   - First instruction is assumed at 0x00400000 for branch/jump encoding.
#   - beq/bne offsets are word offsets relative to (PC + 4).
#   - j/jal targets are absolute word addresses (addr >> 2).
#   - Comments start with '#'. Labels are "label:" at start of a line.
#   - Labels are never on their own line -- their corresponding instruction is always on the same line


import sys, re

BASE_PC = 0x00400000

def bin_to_hex(x):
    y = hex(int(x,2))[2:]
    if len(y) < 8:
        y = (8-len(y))*"0" + y
    return y

def dec_to_bin(value, nbits):
    value = int(value)
    fill = "0"
    if value < 0:
        value = (abs(value) ^ 0xffffffff) + 1
        fill = "1"

    value = bin(value)[2:]
    if len(value) < nbits:
        value = (nbits-len(value))*fill + value
    if len(value) > nbits:
        value = value[-nbits:]
    return value

# list of all R-type instructions.
rtypes = [
    'and', 'or', 'xor', 'nor', 'sll', 'srl', 'sra', 'slt', 'add', 'sub', 'jr'
]
# excluding 'nop'

# dict mapping from instruction to its opcode.
op_codes = {
    'r': dec_to_bin(0, 6),
    'j': dec_to_bin(2, 6),
    'jal': dec_to_bin(3, 6),
    'beq': dec_to_bin(4, 6),
    'bne': dec_to_bin(5, 6),
    'addi': dec_to_bin(8, 6),
    'slti': dec_to_bin(10, 6),
    'andi': dec_to_bin(12, 6),
    'ori': dec_to_bin(13, 6),
    'xori': dec_to_bin(14, 6),
    'lw': dec_to_bin(35, 6),
    'sw': dec_to_bin(43, 6)
}

# dict mapping from R-type instruction to its function code
function_codes = {
    'sll': dec_to_bin(0, 6),
    'srl': dec_to_bin(2, 6),
    'sra': dec_to_bin(3, 6),
    'jr': dec_to_bin(8, 6),
    'add': dec_to_bin(32, 6),
    'sub': dec_to_bin(34, 6),
    'and': dec_to_bin(36, 6),
    'or': dec_to_bin(37, 6),
    'xor': dec_to_bin(38, 6),
    'nor': dec_to_bin(39, 6),
    'slt': dec_to_bin(42, 6)
}

# dict mapping from regsiter name to register value
registers = {
    '$zero': dec_to_bin(0,5), '$at': dec_to_bin(1,5),
    '$v0': dec_to_bin(2,5), '$v1': dec_to_bin(3,5),
    '$a0': dec_to_bin(4,5), '$a1': dec_to_bin(5,5),
    '$a2': dec_to_bin(6,5), '$a3': dec_to_bin(7,5),
    '$t0': dec_to_bin(8,5), '$t1': dec_to_bin(9,5),
    '$t2': dec_to_bin(10,5), '$t3': dec_to_bin(11,5),
    '$t4': dec_to_bin(12,5), '$t5': dec_to_bin(13,5),
    '$t6': dec_to_bin(14,5), '$t7': dec_to_bin(15,5),
    '$s0': dec_to_bin(16,5), '$s1': dec_to_bin(17,5),
    '$s2': dec_to_bin(18,5), '$s3': dec_to_bin(19,5),
    '$s4': dec_to_bin(20,5), '$s5': dec_to_bin(21,5),
    '$s6': dec_to_bin(22,5), '$s7': dec_to_bin(23,5),
    '$t8': dec_to_bin(24,5), '$t9': dec_to_bin(25,5),
    '$k0': dec_to_bin(26,5), '$k1': dec_to_bin(27,5),
    '$gp': dec_to_bin(28,5), '$sp': dec_to_bin(29,5),
    '$fp': dec_to_bin(30,5), '$ra': dec_to_bin(31,5),
}
# also allow to name regs by number e.g. $0 - $31
for i in range(32):
    registers[f'${i}'] = dec_to_bin(i, 5)

def parse_reg(token, line_num):
    token = token.strip()
    if token not in registers:
        raise ValueError(f"Line {line_num}: unknown register '{token}'")
    return registers[token]

def parse_offset_base(arg, line_num):
    # `imm(base)`
    m = re.fullmatch(r'\s*([-+]?(?:0x)?[0-9a-fA-F]+)\s*\(\s*(\$\w+|\$\d+)\s*\)\s*', arg) # +/-? 0x? decimal/hex ($reg | $31)
    if not m:
        raise ValueError(f"Line {line_num}: bad memory operand '{arg}'")
    imm_str, base_reg = m.group(1), m.group(2)
    imm = dec_to_bin(int(imm_str, 0), 16)
    rs = parse_reg(base_reg, line_num)
    return rs, imm

class Assembler():
    '''
    Two-pass MIPS assembler.
    First pass collects labels and stores parsed lines with addresse, line number, instruction, and args.
    Second pass encodes to 32-bit machine code words printed as 8 hex digits (without the preceding 0x).
    '''

    def assemble(self, optionalfile=None):
        labels = {}        # Map from label to its address: label --> address
        parsed_lines = []  # List of parsed instructions.
        pc = BASE_PC        # Track the current address of the instruction.
        line_count = 0     # Number of lines.

        if optionalfile:
            f = open(optionalfile, "r")
        else:
            me, fname = sys.argv
            f = open(fname, "r")

        # 1st pass: map labels to addresses
        for raw in f:
            line_count += 1
            line = raw.split('#',1)[0] # strip comments
            # don't do anything for empty lines
            if line.strip() == "":
                continue

            # check for label
            label_match = re.match(r'^\s*([A-Za-z_]\w*)\s*:\s*(.*)$', line) # (label): (rest)
            if label_match:
                label = label_match.group(1)
                rest = label_match.group(2)
                labels[label] = pc
                line = rest
                if line.strip() == "":
                    # label-only line
                    continue
                
            # instruction and args
            # split by commas and whitespace, preserve register tokens
            tokens = [t.strip() for t in re.split(r'[,\s]+', line.strip()) if t.strip()]
            if not tokens:
                continue

            instr = tokens[0].lower()
            args = tokens[1:]

            # store address, line number, instr, and args of this line
            parsed_lines.append({
                'addr': pc,
                'line_number': line_count,
                'instruction': instr,
                'args': args
            })
            pc += 4
        f.close()

        # 2nd pass: encode everything
        for line in parsed_lines:
            instr = line['instruction']
            args = line['args']
            addr = line['addr']
            ln = line['line_number']

            if instr == 'nop':
                print(8*'0')
                continue

            # R-type
            if instr in rtypes:
                op = op_codes['r']
                shamt = dec_to_bin(0,5)
                rs = rt = rd = dec_to_bin(0,5)
                funct = function_codes[instr]

                if instr in ('add', 'sub', 'and', 'or', 'xor', 'nor', 'slt'):
                    # `instr rd, rs, rt` format
                    if len(args) != 3:
                        raise ValueError(f"Line {ln}: {instr} expects 3 args")
                    rd = parse_reg(args[0], ln)
                    rs = parse_reg(args[1], ln)
                    rt = parse_reg(args[2], ln)
                
                elif instr in ('sll', 'srl', 'sra'):
                    # `instr rd, rt, shamt`
                    if len(args) != 3:
                        raise ValueError(f"Line {ln}: {instr} expects 3 args")
                    rd = parse_reg(args[0], ln)
                    rt = parse_reg(args[1], ln)
                    shamt = dec_to_bin(int(args[2], 0), 5)
                
                elif instr == 'jr':
                    # `jr rs`
                    if len(args) != 1:
                        raise ValueError(f"Line {ln}: jr expects 1 args")
                    rs = parse_reg(args[0], ln)

                machine = op + rs + rt + rd + shamt + funct
                print(bin_to_hex(machine))
                continue

            # J-type
            if instr in ('j', 'jal'):
                # `instr label`
                if len(args) != 1:
                    raise ValueError(f"Line {ln}: {instr} expects 1 arg")
                op = op_codes[instr]
                target_label = args[0]
                if target_label not in labels:
                    raise ValueError(f"Line {ln}: unknown label '{target_label}'")
                target_addr = labels[target_label]
                # Store word address (addr >> 2)
                imm26 = dec_to_bin(target_addr >> 2, 26)
                machine = op + imm26
                print(bin_to_hex(machine))
                continue

            # I-type
            if instr in ('addi', 'andi', 'ori', 'xori', 'slti'):
                # `instr rt, rs, imm`
                if len(args) != 3:
                    raise ValueError(f"Line {ln}: {instr} expects 3 args")
                op = op_codes[instr]
                rt = parse_reg(args[0], ln)
                rs = parse_reg(args[1], ln)
                imm = dec_to_bin(int(args[2], 0), 16)
                machine = op + rs + rt + imm
                print(bin_to_hex(machine))
                continue
            elif instr in ('beq', 'bne'):
                # `instr rs, rt, label`
                if len(args) != 3:
                    raise ValueError(f"Line {ln}: {instr} expects 3 args")
                op = op_codes[instr]
                rs = parse_reg(args[0], ln)
                rt = parse_reg(args[1], ln)
                label = args[2]
                if label not in labels:
                    raise ValueError(f"Line {ln}: unknown label '{label}'")
                next_pc = addr + 4 # offset relative to pc + 4
                label_addr = labels[label]
                offset = (label_addr - next_pc) // 4 # offset of label from pc + 4 -- don't store 2 MSB (implied from pc)
                imm = dec_to_bin(offset, 16)
                machine = op + rs + rt + imm
                print(bin_to_hex(machine))
                continue
            
            elif instr in ('lw', 'sw'):
                # `intr rt, imm(rs)`
                if len(args) != 2:
                    raise ValueError(f"Line {ln}: {instr} expects 2 args")
                op = op_codes[instr]
                rt = parse_reg(args[0], ln)
                rs, imm = parse_offset_base(args[1], ln)
                machine = op + rs + rt + imm
                print(bin_to_hex(machine))
                continue
            
            # if none of the instructions got recognized, it's unknown
            raise ValueError(f"Line {ln}: unknown instruction '{instr}'")


if __name__ == "__main__":
    my_assembler = Assembler()  # instantiate
    my_assembler.assemble()     # assemble (pulling from commandline arg)
