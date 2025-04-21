#!/bin/bash
get_gpio() #(pin)
{
    local pin=$1;shift
    gpioget `gpiofind "$pin"`
}

set_gpio() # (pin, value)
{
	local pin=$1;shift
	local value=$1;shift
	gpioset -m exit `gpiofind "$pin"`=$value
}

power_on()
{
	echo "Power On Stub"
}

power_off()
{
	echo "Powering Off Stub"

	#Delete HI users
	/bin/bash /usr/bin/delete-hi-user.sh
}

grace_off()
{
	echo "Graceful Power Off Stub"

	#Delete HI users
	/bin/bash /usr/bin/delete-hi-user.sh
}

power_cycle()
{
	power_off
	power_on

	#Delete HI users
	/bin/bash /usr/bin/delete-hi-user.sh
}

power_status()
{
	echo "Host Power Status : "
	local val=`get_gpio RUN_POWER_PG-I`
	if [ "$val" == "0" ]; then
                echo "OFF"
        else
                echo "Good / ON"
        fi

}

### MAIN ###
if [ $# -eq 0 ]; then
	echo "$0 <power_status|power_on|power_off|grace_off|power_cycle>"
	exit 1
fi

echo "Host Power Control"

$*
