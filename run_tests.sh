#!/bin/bash

for INSERT_COUNT in {100..1000..100} 
do

    for BULK_COUNT in {500..5000..500} 
    do
        echo "insert: $INSERT_COUNT bulk: $BULK_COUNT"
        mix insert_test $INSERT_COUNT $BULK_COUNT staged >> log_staged
        mix insert_test $INSERT_COUNT $BULK_COUNT direct >> log_direct
    done

done
