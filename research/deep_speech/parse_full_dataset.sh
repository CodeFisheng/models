#!/bin/bash
# Script to run deep speech model to achieve the MLPerf target (WER = 0.23)
# Step 1: download the LibriSpeech dataset.
echo "Data downloading..."
python data/download.py
model_dir="./model_dir/"

## After data downloading, the dataset directories are:
train_clean_100="./librispeech_data/train-clean-100/LibriSpeech/train-clean-100.csv"
train_clean_360="./librispeech_data/train-clean-360/LibriSpeech/train-clean-360.csv"
train_other_500="./librispeech_data/train-other-500/LibriSpeech/train-other-500.csv"
dev_clean="./librispeech_data/dev-clean/LibriSpeech/dev-clean.csv"
dev_other="./librispeech_data/dev-other/LibriSpeech/dev-other.csv"
test_clean="./librispeech_data/test-clean/LibriSpeech/test-clean.csv"
test_other="./librispeech_data/test-other/LibriSpeech/test-other.csv"

# Step 2: generate train dataset and evaluation dataset
echo "Data preprocessing..."
train_file="./librispeech_data/train_dataset.csv"
eval_file="./librispeech_data/eval_dataset.csv"

head -1 $train_clean_100 > $train_file
for filename in $train_clean_100 $train_clean_360 $train_other_500
do
    sed 1d $filename >> $train_file
done

head -1 $dev_clean > $eval_file
for filename in $dev_clean $dev_other
do
    sed 1d $filename >> $eval_file
done

# Step 3: filter out the audio files that exceed max time duration.
final_train_file="./librispeech_data/final_train_dataset.csv"
final_eval_file="./librispeech_data/final_eval_dataset.csv"

echo $final_train_file
echo $final_eval_file

MAX_AUDIO_LEN=27.0
awk -v maxlen="$MAX_AUDIO_LEN" 'BEGIN{FS="\t";} NR==1{print $0} NR>1{cmd="soxi -D "$1""; cmd|getline x; if(x<=maxlen) {print $0}; close(cmd);}' $train_file > $final_train_file
awk -v maxlen="$MAX_AUDIO_LEN" 'BEGIN{FS="\t";} NR==1{print $0} NR>1{cmd="soxi -D "$1""; cmd|getline x; if(x<=maxlen) {print $0}; close(cmd);}' $eval_file > $final_eval_file

# Step 4: run the training and evaluation loop in background, and save the running info to a log file
echo "Model training and evaluation..."
start=`date +%s`

log_file=log_fp32_`date +%Y-%m-%d`
#nohup python deep_speech.py --model_dir=$model_dir --train_data_dir=$final_train_file --eval_data_dir=$final_eval_file --num_gpus=-1  --seed=1 >$log_file 2>&1&

end=`date +%s`
runtime=$((end-start))
echo "Model training time is" $runtime "seconds."
