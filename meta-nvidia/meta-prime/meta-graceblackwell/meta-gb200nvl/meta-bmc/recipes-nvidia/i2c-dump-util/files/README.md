# I2C dump util

Read more about design [here](https://docs.google.com/document/d/15wsQxwxEZWa7OlqIuS8R418Evw1sd2BPA1SpdCwBkTU/edit#)

## How to use
1. The "i2c-dump-util" directory has built in "/usr/share/".
2. Run the tool with "/usr/share/i2c-dump-util/i2c_dump_util.sh [Dump type] [Dump name]" where dump type is a number between 1 and 3 with following meaning:
   1. HMC dump
   2. FPGA Reg Table
   3. ERoT
   - Dump name - what will be the name of the dump after download. The name can be anything, by default "dump.tar.xz".

## How to test
1. The test tools have built in "/usr/share/i2c-dump-util/tests/".
2. Run the test tool with "/usr/share/i2c-dump-util/tests/test_$case.sh".
