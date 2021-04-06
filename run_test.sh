#!/bin/bash
# test options
root_path=data
video_path=makehuman_videos/jpg
#annotation_path=makehuman.json
#result_path=results/result_$JOB_ID
#result_path=results/result_6774073
dataset=makehuman
model=resnet
model_depth=34
batch_size=128
n_threads=`cat /proc/cpuinfo | grep processsor | wc -l`
n_classes=31
#resume_path=results/result_6686170/save_200.pth  # ft (fc)
#resume_path=results/result_6774073/save_200.pth  # ft (layer1)
#resume_path=results/result_6774870/save_200.pth  # ft (conv1)
resume_path=results/result_6698300/save_200.pth  # scratch
result_path=`dirname $resume_path`
annotation_path=$result_path/makehuman.json
output_topk=$n_classes
inference_batch_size=1
inference_subset=test
inference_crop=center  # (center | nocrop)
# inference_no_average="--inference_no_average"

#mkdir -p $root_path/$result_path

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
	--inference_subset $inference_subset \
	--inference_crop $inference_crop $inference_no_average
