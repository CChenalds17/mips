# Testing Methodology

## `dead_registers.mem`

This was provided on Canvas. I ran it in Vivado and inspected the waveform viewer to verify that all registers (except for $0) were set to `0x0000DEAD`. (Note: I had to edit the file to also set $1 --- it erroneously set $2 twice). This verified `addi` functionality.

## `dead_memory.mem`

I ran it on the FPGA and inspected the memory dump to verify that `0x0000DEAD` was stored into memory.

This verified `ori` and `sw` functionality.

## c_test.asm

This was provided on Canvas. I ran this on the FPGA and compared the dump to the expected values in `c_test_out.txt`

## `test.asm`

I wrote this testing script. I simply test instructions individually, and inspect them in the waveform viewer to verify that the registers update accordingly. For lw and sw instructions, I ran this on the FPGA and inspected the memory dump to verify correct values. This must be loaded with test_data.mem (to verify lw). See comments for expected behavior.
