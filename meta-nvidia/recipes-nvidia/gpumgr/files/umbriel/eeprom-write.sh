declare -a b=("FF" "FF" "FF" "FF" "FF" "FF" "FF" "FF")

I2C_BMC_HMC_BUS_RO=0
I2C_BMC_HMC_RO_SLAVE_ADDRESS=54
I2C_BMC_HMC_SLAVE_MEM_FILE=/sys/bus/i2c/devices/$I2C_BMC_HMC_BUS_RO-10$I2C_BMC_HMC_RO_SLAVE_ADDRESS/slave-eeprom

check_eeprom_existence() {
    if [ -e "$I2C_BMC_HMC_SLAVE_MEM_FILE" ]; then
        return 0  # File exists
    else
        return -1  # File does not exist
    fi
}

function eeprom_write()
{
    echo "eprom write"

    #gpu dram temp sensors
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=25 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=29 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=33 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=37 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=41 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=45 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=49 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=53 status=none
    echo -n -e \\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=1 seek=57 status=none

    #nvswitch temp sensors
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=58 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=62 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=66 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=70 status=none
    echo -n -e \\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=1 seek=74 status=none

    #gpu power sensors
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=75 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=79 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=83 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=87 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=91 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=95 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=99 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=103 status=none
    echo -n -e \\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=1 seek=107 status=none

    #gpu temp sensors
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=108 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=112 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=116 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=120 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=124 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=128 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=132 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=136 status=none
    echo -n -e \\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=1 seek=140 status=none

    #gpu energy sensors
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=8 seek=141 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=8 seek=149 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=8 seek=157 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=8 seek=165 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=8 seek=173 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=8 seek=181 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=8 seek=189 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]}\\x${b[7]}\\x${b[6]}\\x${b[5]}\\x${b[4]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=8 seek=197 status=none
    echo -n -e \\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=1 seek=205 status=none

    #gpu dram power sensors
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=206 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=210 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=214 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=218 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=222 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=226 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=230 status=none
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=234 status=none
    echo -n -e \\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=1 seek=238 status=none

    #hmc totoal hsc power
    echo -n -e \\x${b[3]}\\x${b[2]}\\x${b[1]}\\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=4 seek=247 status=none
    echo -n -e \\x${b[0]} | dd of=$I2C_BMC_HMC_SLAVE_MEM_FILE bs=1 count=1 seek=251 status=none
}

check_eeprom_existence
file_exists=$?

if [ $file_exists -eq 0 ]; then
    eeprom_write
fi
