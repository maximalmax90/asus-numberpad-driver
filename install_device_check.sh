#!/bin/bash

source non_sudo_check.sh

INTERFACES=$(for i in $(i2cdetect -l | grep DesignWare | sed -r "s/^(i2c\-[0-9]+).*/\1/"); do echo $i; done)
if [ -z "$INTERFACES" ]; then
    echo "No i2c interface can be found. Make sure you have installed libevdev packages"
    exit 1
fi

TOUCHPAD_WITH_NUMBERPAD_DETECTED=false
for INDEX in $INTERFACES; do
    echo -n "Testing interface $INDEX: "

    NUMBER=$(echo -n $INDEX | cut -d'-' -f2)
    NUMBERPAD_OFF_CMD="i2ctransfer -f -y $NUMBER w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"

    I2C_TEST=$($NUMBERPAD_OFF_CMD 2>&1)
    if [ -z "$I2C_TEST" ]; then
        echo "success"
        TOUCHPAD_WITH_NUMBERPAD_DETECTED=true
        break
    else
        echo "failed"
    fi
done

if [ "$TOUCHPAD_WITH_NUMBERPAD_DETECTED" ]; then
    echo "The detection was successful. Touchpad with numberpad found: $INDEX"
else
    echo "The detection was not successful. Touchpad with numberpad not found"
    exit 1
fi