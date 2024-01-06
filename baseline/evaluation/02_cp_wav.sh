#!/bin/bash

root_dir=/data/yh/Voice-Privacy-Challenge-2020/baseline

cd $root_dir

. path.sh
. cmd.sh

scp_dir="$root_dir/corpora/test_utt_list_2/data"
target_dir="$root_dir/corpora/test_utt_list_2/original_wav"


for dset in libri_dev_{enrolls,trials_f,trials_m} \
              vctk_dev_{enrolls,trials_f_all,trials_m_all} \
              libri_test_{enrolls,trials_f,trials_m} \
              vctk_test_{enrolls,trials_f_all,trials_m_all} \
              vctk_dev_{trials_f_common,trials_m_common} \
              vctk_test_{trials_f_common,trials_m_common}; do
    # 设置scp文件和目标目录
    scp_file="$scp_dir/$dset/wav.scp"
    echo "scp_file:$scp_file"
    enroll_dir="$target_dir/$dset"
    echo "enroll_dir:$enroll_dir"    

    mkdir -p "$enroll_dir"

    # while IFS=read -r line
    while IFS=' ' read -r -a line
    do 
        key="${line[0]}"
        if [[ "${key}" =~ "-" ]];then
            dir=${key%%-*}
        elif [[ "${key}" =~ "_" ]];then
            dir=${key%%_*}
        fi
        # echo "key:$key"
        wav_path="${line[1]}"
        echo "${dir}"
        echo "wav_path:$wav_path"
        # wav_name=${wav_path##*/}
        # echo "wav_name: $wav_name"
        mkdir -p "$enroll_dir/$dir"
        # target_wav="$enroll_dir/$key/$wav_name"
        target_wav="$enroll_dir/$dir/$key.wav"
        echo "target_wav:$target_wav"
        cp "$root_dir/$wav_path" "$target_wav"

    done < $scp_file
done
cd $target_dir
cd ..
echo "$PWD"
zip -r original_wav.zip original_wav/






