#!/bin/bash
COUNTER_FILE="/tmp/heart_beat_count.txt"
if [ -f "$COUNTER_FILE" ]; then
	counter=$(<"$COUNTER_FILE")
else
	counter=0
fi

get_flow_ctrl() {
     status=`busctl get-property xyz.openbmc_project.Settings /xyz/openbmc_project/Control/Diag xyz.openbmc_project.Control.Diag DiagStatus | cut -d ' ' -f 2`
     if [ $status -eq 0 ]; then
	 counter=$((counter+1))
	 echo $counter > "$COUNTER_FILE"
	 if [ "$counter" -eq 3 ]; then
	     busctl set-property xyz.openbmc_project.Settings /xyz/openbmc_project/Control/Diag xyz.openbmc_project.Control.Diag DiagStatus y 3 
	     echo "Please check the CPU"
	     rm "$COUNTER_FILE"
	 fi
     elif [ $status -eq 1 ]; then
	 busctl set-property xyz.openbmc_project.Settings /xyz/openbmc_project/Control/Diag xyz.openbmc_project.Control.Diag DiagStatus y 0
	 echo "Test cases in progress"
	 echo 0 > "$COUNTER_FILE" 
     elif [ $status -eq 2 ]; then
	 echo "Test finished"
	 echo 0 > "$COUNTER_FILE" 
     elif [ $status -eq 4 ]; then
	 echo "Test not started"
	 echo 0 > "$COUNTER_FILE" 
     fi 
}

status=$(get_flow_ctrl)
echo "$status"

