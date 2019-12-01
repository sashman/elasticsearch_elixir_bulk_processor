#!/bin/bash

for INSERT_COUNT in {100..10000..100} 
do

    for BULK_COUNT in {10..5000..10} 
    do
        mix insert_test $INSERT_COUNT $BULK_COUNT staged
    done

done
