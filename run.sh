#!/bin/bash
# train options
#root_path=$SGE_LOCALDIR/data
root_path=data
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
result_path=results/result_$JOB_ID
model_path=models
dataset=makehuman
n_pretrain_classes=700
pretrain_path=models/r3d34_K_200ep.pth
ft_begin_module=fc
model=resnet
model_depth=34
batch_size=128
# n_threads=4
n_threads=16
checkpoint=10
resume_path=$result_path/save_200.pth
output_topk=5
inference_batch_size=1

result_dir=$root_path/$result_path
mkdir -p $result_dir
cp $root_path/$annotation_path $result_dir

# dataset options
# dataset_src=data.tar.bz2
# pretrain_src=pretrain/r3d34_K_200ep.pth
# result_dst=$result_path/result_$JOB_ID
# check_data=$HOME/repos/mogen/check_data.sh
mocap_labels=$HOME/repos/mogen/utils/mocap_labels.json
blacklist=$HOME/repos/mogen/utils/blacklist.txt

# other options
mkdir -p logs
log_path=logs/log_$JOB_ID.txt
# log_dst=$log_path/log_$JOB_ID.txt
# extract_dataset=no

# if [ $extract_dataset = yes ]; then
#     # 
# fi

#timestamp=`date +%s`

# make log file
echo "jobid: $JOB_ID" > $log_path
#echo "timestamp: $timestamp" >> $log_path
echo "" >> $log_path

# symbolic link
# ln -s $root_path/$result_path $result_dst

# make/check directory for result/log
# mkdir -p $result_dst
# mkdir -p $log_path

# extract
# tar xf $dataset_src -C $SGE_LOCALDIR

# check dataset
# $check_data $root_path/$video_path
# du -sm $root_path/$video_path

# generate annotation file
# echo "generate annotation file"
# echo "------------------------"
# python3 util_scripts/makehuman_json.py --root $root_path --min_inst 120 --mocap_labels $mocap_labels --blacklist $blacklist
# echo ""

# check anntation file and set n_classes
# echo "check annotation file" >> $log_path
# echo "---------------------" >> $log_path
# python3 util_scripts/check_annotation.py --annotation_path $root_path/$annotation_path >> $log_path
n_classes=`python3 util_scripts/check_annotation.py --annotation_path $root_path/$annotation_path --n_classes`
n_instances=`python3 util_scripts/check_annotation.py --annotation_path $root_path/$annotation_path --n_instances`
# echo "" >> $log_path

# copy annotation file
# cp $root_path/$annotation_path $result_dst

# set pretrain model and result directory
# mkdir -p $root_path/$model_path
# mkdir -p $root_path/$result_path
# cp $pretrain_src $root_path/$model_path

# show params
echo "dataset" >> $log_path
echo "-------" >> $log_path
echo "kind: $dataset" >> $log_path
echo "# of instances: $n_instances" >> $log_path
# echo "src: $dataset_src" >> $log_path
echo "pretrain model: $pretrain_src" >> $log_path
echo "" >> $log_path

echo "network" >> $log_path
echo "-------" >> $log_path
echo "model: $model" >> $log_path
echo "model depth: $model_depth" >> $log_path
echo "batch size: $batch_size" >> $log_path
echo "# of classes: $n_classes" >> $log_path
echo "# of pretrain classes: $n_pretrain_classes" >> $log_path
echo "" >> $log_path

# echo "result" >> $log_path
# echo "------" >> $log_path
# echo $result_dst >> $log_path
# echo "" >> $log_path

echo "time elapsed (min)" >> $log_path
echo "------------------" >> $log_path
t_begin=$SECONDS
# t_extract=$SECONDS
# echo "extract: $((t_extract/60))" >> $log_path

# scratch
# python3 main.py \
#     --root_path $root_path \
#     --video_path $video_path \
#     --annotation_path $annotation_path \
#     --result_path $result_path \
#     --dataset $dataset \
#     --n_classes $n_classes \
#     --model $model \
#     --model_depth $model_depth \
#     --batch_size $batch_size \
#     --n_threads $n_threads \
#     --checkpoint $checkpoint

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
    --checkpoint $checkpoint #--no_cuda

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
    --inference_batch_size $inference_batch_size #--no_cuda

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

# copy LOCALDIR to HOME
# cp $root_path/$result_path/* $result_dst
# cp $root_path/$annotation_path $result_dst

echo "total: $((SECONDS/60))" >> $log_path

echo ""
echo "--------------------"
echo "complete! $((SECONDS/60/60)) hours"
