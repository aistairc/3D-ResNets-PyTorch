#!/bin/bash

#$ -l rt_F=1
#$ -j y
#$ -cwd

source /etc/profile.d/modules.sh
module load python/3.6/3.6.5 cuda/10.1/10.1.243 cudnn/7.6/7.6.5
source ~/venv/pytorch/bin/activate

./run.sh

deactivate
