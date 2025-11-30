
# sys.path.insert(1, 'library/')
# import sw_xem_library

###########
# IMPORTS #
###########
# Default libs
import argparse
from re import L
#from socket import IP_DEFAULT_MULTICAST_LOOP
import string
import sys
import argparse
from datetime import datetime

# OK and CS1410 libs
sys.path.insert(0,"../../../lib")
import cs1410_lib.utils as cs1410
ok = cs1410.import_oklib(verbose=True)
import cs1410_lib.xem as xem

# DATA FORMATTING
def fpga_out_to_list (output, dims):
    list = []
    i = 0
    for byte in range(0, len(output), 4):
        if i == dims:
            break
        # Convert each group of 4 bytes to an integer using little-endian byte order
        word = int.from_bytes(output[byte:byte+4], byteorder='little')
        list.append(word)
        i += 1
    return list

def compare_lists(list1, list2):
    if len(list1) != len(list2):
        return False

    for elem1, elem2 in zip(list1, list2):
        if elem1 != elem2:
            return False
    return True

def print_matrix(input_list, nb_rows, nb_columns):
    if len(input_list) != nb_rows * nb_columns:
        print("Invalid input: The size of the list does not match the specified number of rows and columns.")
        return

    for i in range(nb_rows):
        row_values = input_list[i * nb_columns: (i + 1) * nb_columns]
        print("  ".join(map(str, row_values)))


def convert_list_to_bytearray(input_list):
    output_bytearray = bytearray()

    for num in input_list:
        # Convert each integer to little endian format (4 bytes)
        byte_representation = num.to_bytes(4, byteorder='little')
        
        # Append the bytes to the output bytearray
        output_bytearray.extend(byte_representation)

    return output_bytearray
def print_bytearray_buf_to_file(buffer, r, c, filename="fpga_output.txt"):
    """Write bytearray buffer contents to a file in hexadecimal format"""
    with open(filename, 'w') as f:
        rows = 0
        columns = 0
        for byte in range(0, len(buffer), 4):
            if rows == r:
                break
            
            if columns == c:
                rows += 1
                if rows == r:
                    break
                
                columns = 1
                word = int.from_bytes(buffer[byte:byte+4], byteorder='little')
                f.write(f"{hex(byte)} | 0x{word:08X}\n")
                continue
            
            word = int.from_bytes(buffer[byte:byte+4], byteorder='little')
            f.write(f"{hex(byte)} | 0x{word:08X}\n")
            columns += 1
        
        f.write("\n")
    
    print(f"Output written to {filename}")
def print_bytearray_buf_decimal(buffer, r, c): #print a bytearray in decimal format (r rows, c elements each: 2D array. r and c are used for nicer formatting)
    rows = 0
    columns = 0
    for byte in range(0, len(buffer), 4):
        if rows == r:
            break

        
        if columns == c:
            rows += 1
            #print ("\n")
            if rows == r:
                break
            
            columns = 1
            word = int.from_bytes(buffer[byte:byte+4], byteorder='little')
            print(hex(byte),  " | ", word) #, end='  ')
            continue
        
        # Convert each group of 4 bytes to an integer using little-endian byte order
        word = int.from_bytes(buffer[byte:byte+4], byteorder='little')
        print(hex(byte), " | ", word) #, end='  ')
        columns += 1
        
    print("\n")	

def Reset(dev):
    
    #reset_div (clock divider in OK wrapper)
    dev.setWire(0x11, 0xFF, 0x01)
    dev.setWire(0x11, 0x00, 0x01)

    #buf_reset (the RAM address pointer).		
    dev.setTrigger(0x40, 0)
    print("just resetted input buffer")
    



def Run(dev, signals, flash_ram, data_ram):


    #dev.setWire(0x12, 0x00, 0x01)
    dev.setWire(0x12, 0xFF, 0x01)

    input_ram = data_ram + flash_ram
    #input_ram = flash_ram + data_ram
    input_ram_ok = convert_list_to_bytearray(input_ram)
    
    dev.writeBuffer(0x80, input_ram_ok)
    

    # Give start_cpu (reset cpu) 
    #dev.setWire(0x12, 0xFF, 0x01)
    dev.setWire(0x12, 0x00, 0x01)


    #wait 
    for i in range(1000):
        print(".", end = " ")


    #REG FILE
    regs = []
    
    for r in range(32, 64, 1):
        reg = dev.getWire(r, 0xFFFFFFFF)
        regs.append(reg)
    
    reg_labels = ["Reg 0 ($zero)", "Reg 1 ($at) ", "Reg 2 ($v0) ", "Reg 3 ($v1) ", "Reg 4 ($a0) ", "Reg 5 ($a1) ", "Reg 6 ($a2) ", "Reg 7 ($a3) ", "Reg 8 ($t0) ", "Reg 9 ($t1) ", "Reg 10 ($t2)", "Reg 11 ($t3)", "Reg 12 ($t4)", "Reg 13 ($t5)", "Reg 14 ($t6)", "Reg 15 ($t7)", "Reg 16 ($s0)", "Reg 17 ($s1)", "Reg 18 ($s2)", "Reg 19 ($s3)", "Reg 20 ($s4)", "Reg 21 ($s5)", "Reg 22 ($s6)", "Reg 23 ($s7)", "Reg 24 ($t8)", "Reg 25 ($t9)", "Reg 26 ($k0)", "Reg 27 ($k1)", "Reg 28 ($gp)", "Reg 29 ($sp)", "Reg 30 ($fp)", "Reg 31 ($ra)"]
    

    print("\nREGS:\n")
    for r in range(32):
        print(reg_labels[r], " : ", f"0x{regs[r]:08X}")

    

    #RAM contents (decimal representation!)
    output_len = 1536																			
    #multiples of 16 bytes?
    output = dev.readBuffer(0xA0, (1536)*4 )[4:] #K.K off-by-1 addressing error when reading out due to BRAM 2-cycle latency I think.

    

    print(". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ")
    print("---Output from FPGA RAM ---")
    print("address | content")
    print("\n")

    print_bytearray_buf_to_file(output, 1024+512, 1)

    return True




def CPrint(*obj, sep=' ', end='\n', file=sys.stdout, flush=False):
    print(*obj, sep=sep, end=end, file=file, flush=flush)


def read_instructions(file_name):
    with open(file_name, 'r') as file:
        lines = file.readlines()
    return [int(line.strip(), 16) for line in lines if line.strip()]

def generate_flash_ram(instructions, total_length=512):
    return instructions + [0] * (total_length - len(instructions))

def load_data_mem(file_path):
    data_ram = [0] * 1024  # Initialize a list with 1024 elements, all set to 0

    with open(file_path, 'r') as file:
        for line in file:
            # Split the line by the '|' delimiter and strip any leading/trailing whitespace
            address_str, content_str = [part.strip() for part in line.split('|')]

            # Convert the address from hexadecimal to an integer index
            address = int(address_str, 16)

            # Convert the content to an integer
            content = int(content_str)

            # Calculate the index in the data_ram list (assuming addresses are in steps of 4)
            index = address // 4

            # Store the content at the calculated index
            data_ram[index] = content

    return data_ram

def main(flash_file_name, data_file_name):
    instructions = read_instructions(flash_file_name)
    flash_ram = generate_flash_ram(instructions)
    data_ram = load_data_mem(data_file_name)
    
    signals = True

    dev = xem.Device(True)

    result = dev.Initialize()
    if not result:
        exit(1)

    info = dev.getInfo()
    if info is None:
        exit(1)

    print("product:")
    CPrint("         Product: " + info.productName)
    CPrint("Firmware version: %d.%d" % (info.deviceMajorVersion, info.deviceMinorVersion))
    CPrint("   Serial Number: %s" % info.serialNumber)
    CPrint("       Device ID: %s" % info.deviceID)
    CPrint("       Generated: %s" % datetime.now())

    dev.setupClock()

    bitfile = "cpu_top.bit"
    if not dev.downloadFile(bitfile):
        exit(1)

    Reset(dev)
    print("Reset Done!")

    if Run(dev, signals, flash_ram, data_ram):
        exit(0)
    else:
        exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 main.py <instr_file> <data_file>")
    else:
        instr_file = sys.argv[1]
        data_file = sys.argv[2]
        main(instr_file, data_file)
