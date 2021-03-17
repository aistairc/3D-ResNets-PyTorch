#!/bin/bash
n_rows=$((`tput lines`-2))
log_path=$1

if [ -z "$log_path" ]; then
    log_path=`ls -1 run_batch.sh.o* | tail -1`
fi

watch tail -$n_rows $log_path
