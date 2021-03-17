#!/bin/bash
root_path=$SGE_LOCALDIR/data
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
result_path=results
model_path=models
log_path=logs
dataset=makehuman
#n_classes=2535
n_pretrain_classes=700
pretrain_path=models/r3d34_K_200ep.pth
ft_begin_module=fc
model=resnet
model_depth=34
batch_size=128
n_threads=4
checkpoint=5
resume_path=$root_path/results/save_200.pth
output_topk=5
inference_batch_size=1

dataset_src=data.tar.bz2
pretrain_src=pretrain/r3d34_K_200ep.pth
timestamp=`date +%s`
result_dst=$result_path/result_$timestamp
log_dst=$log_path/log_$timestamp
# mocap_labels=$HOME/repos/mogen/utils/mocap_labels.json
# blacklist=$HOME/repos/mogen/utils/blacklist.txt


# make/check directory for result/log
mkdir -p $result_dst
mkdir -p $log_path
# unpack
tar -jxvf $dataset_src -C $SGE_LOCALDIR > /dev/null
n_classes=`python3 util_scripts/makehuman_json.py --root $root_path --get_n_classes`
# (option) mocap_labels
if [ -z $mocap_labels ]; then
    cp $mocap_labels $root_path
fi
# (option) blacklist
if [ -z $backlist ]; then
    cp $blacklist $root_path
fi
# generate annotation file
python3 util_scripts/makehuman_json.py --root $root_path
cp $root_path/$annotation_path $result_dst
mkdir -p $root_path/$result_path
mkdir -p $root_path/$model_path
cp $pretrain_src $root_path/$model_path

# show params
echo "timestamp: $timestamp" > $log_dst
echo "" >> $log_dst

echo "dataset" >> $log_dst
echo "-------" >> $log_dst
echo "kind: $dataset" >> $log_dst
echo "src: $dataset_src" >> $log_dst
echo "pretrain model: $pretrain_src" >> $log_dst
echo "" >> $log_dst

echo "network" >> $log_dst
echo "-------" >> $log_dst
echo "model: $model" >> $log_dst
echo "model depth: $model_depth" >> $log_dst
echo "batch size: $batch_size" >> $log_dst
echo "# of classes: $n_classes" >> $log_dst
echo "# of pretrain classes: $n_pretrain_classes" >> $log_dst
echo "" >> $log_dst

echo "result" >> $log_dst
echo "------" >> $log_dst
echo $result_dst >> $log_dst
echo "" >> $log_dst

echo "time elapsed (sec)" >> $log_dst
echo "------------------" >> $log_dst
echo "unpack: $SECONDS" >> $log_dst

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

# fine-tuning
# python3 main.py \
#     --root_path $root_path \
#     --video_path $video_path \
#     --annotation_path $annotation_path \
#     --result_path $result_path \
#     --dataset $dataset \
#     --n_classes $n_classes \
#     --n_pretrain_classes $n_pretrain_classes \
#     --pretrain_path $pretrain_path \
#     --ft_begin_module $ft_begin_module \
#     --model $model \
#     --model_depth $model_depth \
#     --batch_size $batch_size \
#     --n_threads $n_threads \
#     --checkpoint $checkpoint #--no_cuda

echo "eval 1: $SECONDS" >> $log_dst

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

echo "eval 2: $SECONDS" >> $log_dst

# eval top1 accuracy
python3 -m util_scripts.eval_accuracy \
    $root_path/$annotation_path \
    $root_path/$result_path/val.json \
    --subset validation \
    -k 1 \
    --ignore \
    --save

echo "copy result: $SECONDS" >> $log_dst

# copy LOCALDIR to HOME
cp $root_path/$result_path/* $result_dst
# cp $root_path/$annotation_path $result_dst

echo "total: $SECONDS" >> $log_dst

echo "complete!"
