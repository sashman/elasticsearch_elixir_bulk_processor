#!/bin/bash

for INSERT_COUNT in {1000..10000..1000} 
do

    for BULK_COUNT in {50..500..50} 
    do
        echo "insert: $INSERT_COUNT bulk: $BULK_COUNT"
        mix insert_test $INSERT_COUNT $BULK_COUNT staged >> log_staged
        mix insert_test $INSERT_COUNT $BULK_COUNT direct >> log_direct
    done

done
