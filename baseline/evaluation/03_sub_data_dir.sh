#!/bin/bash

root_dir=/data/yh/Voice-Privacy-Challenge-2020/baseline

cd $root_dir

. path.sh
. cmd.sh


# change this to pretrained xvector model downloaded from Kaldi website
xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a
anon_xvec_out_dir=${xvec_nnet_dir}/anon

# anon wav
# anon_wav_dir=corpora/res/test_utt_list
anon_wav_dir=$root_dir/corpora/test_utt_list_2/anon_wav
anon_data_suffix=_anon

data=corpora/test_utt_list_2/data
# data=corpora/test

RED='\033[0;31m'  # 用于设置文本颜色
NC='\033[0m'      # 用于重置文本颜色

for dset in libri_dev_{enrolls,trials_f,trials_m} \
              vctk_dev_{enrolls,trials_f_all,trials_m_all} \
              libri_test_{enrolls,trials_f,trials_m} \
              vctk_test_{enrolls,trials_f_all,trials_m_all}; do
    printf "${RED}\nStage a.7: Creating new data directories corresponding to anonymization.${NC}\n"
    # 匿名化后的语音文件路径
    # wav_path=${data_netcdf}/${data_dir}/nsf_output_wav
    wav_path=${anon_wav_dir}/${dset}
    new_data_dir=${data}/${dset}${anon_data_suffix}
    if [ -d "$new_data_dir" ]; then
    rm -rf ${new_data_dir}
    fi
    utils/copy_data_dir.sh ${data}/${dset} ${new_data_dir}
    [ -f ${new_data_dir}/feats.scp ] && rm ${new_data_dir}/feats.scp
    [ -f ${new_data_dir}/vad.scp ] && rm ${new_data_dir}/vad.scp
    # Copy new spk2gender in case cross_gender vc has been done
    cp ${anon_xvec_out_dir}/xvectors_${dset}/pseudo_xvecs/spk2gender ${new_data_dir}/
    awk -v p="$wav_path" '{split($1, arr, /[-_]/); print $1, "sox", p"/"arr[1]"/"$1"_anon.wav", "-t wav -R -b 16 - |"}' $data/${dset}/wav.scp > ${new_data_dir}/wav.scp

    if [ -f $data/$dset/enrolls ]; then
        cp $data/$dset/enrolls ${new_data_dir} || exit 1
    else
        [ ! -f $data/$dset/trials ] && echo "File $data/$dset/trials does not exist" && exit 1
        cp $data/$dset/trials ${new_data_dir} || exit 1
    fi
done

echo "create new data directories done.\n"

# Make VCTK anonymized evaluation subsets
# if [ $stage -le 10 ]; then
printf "${GREEN}\nStage 10: Making VCTK anonymized evaluation subsets...${NC}\n"
temp=$(mktemp)
for suff in dev test; do
    dset=$data/vctk_$suff
    for name in ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_m_all$anon_data_suffix; do
        [ ! -d $name ] && echo "Directory $name does not exist" && exit 1
    done

    cut -d' ' -f2 ${dset}_trials_f/trials | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_f${anon_data_suffix} || exit 1
    cp ${dset}_trials_f/trials ${dset}_trials_f${anon_data_suffix} || exit 1

    cut -d' ' -f2 ${dset}_trials_f_common/trials | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_f_all$anon_data_suffix ${dset}_trials_f_common${anon_data_suffix} || exit 1
    cp ${dset}_trials_f_common/trials ${dset}_trials_f_common${anon_data_suffix} || exit 1

    cut -d' ' -f2 ${dset}_trials_m/trials | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_m_all$anon_data_suffix ${dset}_trials_m${anon_data_suffix} || exit 1
    cp ${dset}_trials_m/trials ${dset}_trials_m${anon_data_suffix} || exit 1

    cut -d' ' -f2 ${dset}_trials_m_common/trials | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp ${dset}_trials_m_all$anon_data_suffix ${dset}_trials_m_common${anon_data_suffix} || exit 1
    cp ${dset}_trials_m_common/trials ${dset}_trials_m_common${anon_data_suffix} || exit 1
    done
rm $temp
# fi