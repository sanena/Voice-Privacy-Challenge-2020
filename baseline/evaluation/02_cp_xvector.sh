#!/bin/bash

root_dir=/data/yh/Voice-Privacy-Challenge-2020/baseline

cd $root_dir

. path.sh
. cmd.sh

scp_dir=$root_dir/exp/models/2_xvect_extr/exp/xvector_nnet_1a/anon
target_dir=$root_dir/corpora/test_utt_list_2/xvector

for dset in libri_dev_{enrolls,trials_f,trials_m} \
              vctk_dev_{enrolls,trials_f_all,trials_m_all} \
              libri_test_{enrolls,trials_f,trials_m} \
              vctk_test_{enrolls,trials_f_all,trials_m_all}; do
    scp_file=$scp_dir/xvectors_${dset}
    enroll_dir=$target_dir/$dset
    echo $enroll_dir
    mkdir -p "$enroll_dir"
    
    # 设置scp文件和目标目录
    for file_name in num_utts.ark spk_xvector.ark spk_xvector.scp; do
        
        cp ${scp_file}/$file_name $enroll_dir/$file_name
    done
done
cd $target_dir
cd ..
echo "$PWD"
zip -r xvector.zip xvector