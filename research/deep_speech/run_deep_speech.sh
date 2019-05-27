#!/bin/bash
# Script to run deep speech model to achieve the MLPerf target (WER = 0.23)
# Step 1: download the LibriSpeech dataset.
echo "Data downloading..."
#python data/download.py
prefix="./data_dir/"
echo $prefix

## After data downloading, the dataset directories are:
train_clean_100=$prefix"train-clean-100/LibriSpeech/train-clean-100.csv"
echo $train_clean_100
train_clean_360=$prefix"train-clean-360/LibriSpeech/train-clean-360.csv"
#train_other_500="/tmp/librispeech_data/train-other-500/LibriSpeech/train-other-500.csv"
dev_clean=$prefix"dev-clean/LibriSpeech/dev-clean.csv"
#dev_other="/tmp/librispeech_data/dev-other/LibriSpeech/dev-other.csv"
test_clean=$prefix"test-clean/LibriSpeech/test-clean.csv"
#test_other="/tmp/librispeech_data/test-other/LibriSpeech/test-other.csv"
# Step 2: generate train dataset and evaluation dataset
echo "Data preprocessing..."
train_file=$prefix"train_dataset.csv"
eval_file=$prefix"eval_dataset.csv"

head -1 $train_clean_100 > $train_file
for filename in $train_clean_100 $train_clean_360
do
    echo "start to do train"
    sed 1d $filename >> $train_file
    echo $filename "done"
done

head -1 $dev_clean > $eval_file
for filename in $dev_clean
do
    echo "start to do dev"
    sed 1d $filename >> $eval_file
    echo $filename "done"
done

# Step 3: filter out the audio files that exceed max time duration.
final_train_file=$prefix"final_train_dataset.csv"
final_eval_file=$prefix"final_eval_dataset.csv"
echo "step 2"
MAX_AUDIO_LEN=27.0
awk -v maxlen="$MAX_AUDIO_LEN" 'BEGIN{FS="\t";} NR==1{print $0} NR>1{cmd="soxi -D "$1""; cmd|getline x; if(x<=maxlen) {print $0}; close(cmd);}' $train_file > $final_train_file
echo "step 3"
awk -v maxlen="$MAX_AUDIO_LEN" 'BEGIN{FS="\t";} NR==1{print $0} NR>1{cmd="soxi -D "$1""; cmd|getline x; if(x<=maxlen) {print $0}; close(cmd);}' $eval_file > $final_eval_file
echo "step 4"
# Step 4: run the training and evaluation loop in background, and save the running info to a log file
echo "Model training and evaluation..."
start=`date +%s`

echo "step 5: training now"
log_file=log_`date +%Y-%m-%d`
nohup python deep_speech.py --train_data_dir=$final_train_file --eval_data_dir=$final_eval_file --num_gpus=-1 --wer_threshold=0.23 --seed=1 >$log_file 2>&1&

end=`date +%s`
runtime=$((end-start))
echo "Model training time is" $runtime "seconds."
