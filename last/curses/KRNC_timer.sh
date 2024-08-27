#!/bin/bash

Fifo=$1

while [ -p $Fifo ]
do
    echo Refresh >> $Fifo 2>/dev/null
    sleep 1
done
