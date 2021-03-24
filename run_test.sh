#!/bin/bash
# train options
root_path=data
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
result_path=results/result_$JOB_ID
dataset=makehuman
model=resnet
model_depth=34
batch_size=128
n_threads=20  # if rt_G.large
n_classes=31
resume_path=$root_path/results/result_6686170/save_200.pth
output_topk=$n_classes
inference_batch_size=1
inference_subset=test

# eval topn prob.
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
    --inference_batch_size $inference_batch_size \
    --inference_subset $inference_subset

# eval top1 accuracy
python3 -m util_scripts.eval_accuracy \
    $root_path/$annotation_path \
    $root_path/$result_path/test.json \
    --subset testing \
    -k 1 \
    --ignore \
    --save
