#!/bin/bash

declare -i sleep_cnt=0
while ! mountpoint /var/lib/logging &> /dev/null  
do
    sleep 10
    sleep_cnt=$sleep_cnt+1
    if [ $sleep_cnt -ge 8 ];then
        break
    fi
done