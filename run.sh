#!/bin/bash
date_begin=`date`
is_scratch=yes

# train options
root_path=data
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
result_path=results/result_$JOB_ID
dataset=makehuman
model=resnet
model_depth=34
batch_size=128
#n_threads=4
n_threads=20  # if rt_G.large
checkpoint=10

# fine-tuning options
n_pretrain_classes=700
model_path=models
pretrain_path=$model_path/r3d34_K_200ep.pth
ft_begin_module=fc

# eval options
resume_path=$result_path/save_200.pth
output_topk=5
inference_batch_size=1

result_dir=$root_path/$result_path
mkdir -p $result_dir
cp $root_path/$annotation_path $result_dir

mocap_labels=$HOME/repos/mogen/utils/mocap_labels.json
blacklist=$HOME/repos/mogen/utils/blacklist.txt

# other options
mkdir -p logs
log_path=logs/log_$JOB_ID.txt

# check annotation info
n_classes=`python3 util_scripts/check_annotation.py --annotation_path $root_path/$annotation_path --n_classes`
n_instances=`python3 util_scripts/check_annotation.py --annotation_path $root_path/$annotation_path --n_instances`

# make log file
echo "jobid: $JOB_ID" > $log_path
echo "" >> $log_path

echo "dataset" >> $log_path
echo "-------" >> $log_path
echo "kind: $dataset" >> $log_path
echo "# of instances: $n_instances" >> $log_path
if [ $is_scratch = no ]; then
    echo "pretrain model: $pretrain_path" >> $log_path
fi
echo "" >> $log_path

echo "network" >> $log_path
echo "-------" >> $log_path
if [ $is_scratch = yes ]; then
    echo "fine-tuning: no" >> $log_path
else
    echo "fine-tuning: yes" >> $log_path
fi
echo "model: $model" >> $log_path
echo "model depth: $model_depth" >> $log_path
echo "batch size: $batch_size" >> $log_path
echo "# of classes: $n_classes" >> $log_path
echo "# of pretrain classes: $n_pretrain_classes" >> $log_path
echo "" >> $log_path

echo "time elapsed (min)" >> $log_path
echo "------------------" >> $log_path

t_begin=$SECONDS

# train
if [ $is_scratch = yes ]; then
    # scratch
    python3 main.py \
	--root_path $root_path \
	--video_path $video_path \
	--annotation_path $annotation_path \
	--result_path $result_path \
	--dataset $dataset \
	--n_classes $n_classes \
	--model $model \
	--model_depth $model_depth \
	--batch_size $batch_size \
	--n_threads $n_threads \
	--checkpoint $checkpoint
else
    # fine-tuning
    python3 main.py \
	--root_path $root_path \
	--video_path $video_path \
	--annotation_path $annotation_path \
	--result_path $result_path \
	--dataset $dataset \
	--n_classes $n_classes \
	--n_pretrain_classes $n_pretrain_classes \
	--pretrain_path $pretrain_path \
	--ft_begin_module $ft_begin_module \
	--model $model \
	--model_depth $model_depth \
	--batch_size $batch_size \
	--n_threads $n_threads \
	--checkpoint $checkpoint
fi

t_train=$SECONDS
echo "train: $(((t_train-t_begin)/60))" >> $log_path

# eval top5 prob
python3 main.py \
    --root_path $root_path \
    --video_path $video_path \
    --annotation_path $annotation_path \
    --result_path $result_path \
    --dataset $dataset \
    --resume_path $resume_path \
    --n_classes $n_classes \
    --model $model \
    --model_depth $model_depth \
    --n_threads $n_threads \
    --no_train \
    --no_val \
    --inference \
    --output_topk $output_topk \
    --inference_batch_size $inference_batch_size

t_eval1=$SECONDS
echo "eval 1: $(((t_eval1-t_train)/60))" >> $log_path

# eval top1 accuracy
python3 -m util_scripts.eval_accuracy \
    $root_path/$annotation_path \
    $root_path/$result_path/val.json \
    --subset validation \
    -k 1 \
    --ignore \
    --save

t_eval2=$SECONDS
echo "eval 2: $(((t_eval2-t_eval1)/60))" >> $log_path
echo "total: $((SECONDS/60))" >> $log_path

echo ""
echo "complete!"
echo "--------------------"
echo "jobid: $JOB_ID"
echo "begin: $date_begin"
echo "  end: `date`"
echo "total: $((SECONDS/60/60)) hours"
