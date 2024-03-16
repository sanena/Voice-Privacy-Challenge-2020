#!/bin/bash

nj=$(nproc)
root_dir=/data/yh/Voice-Privacy-Challenge-2020/baseline

cd $root_dir

. path.sh
. cmd.sh

subdata=corpora/test_1_utt_list/data
# Make evaluation data
printf "${GREEN}\nStage 8: Making evaluation subsets...${NC}\n"
temp=$(mktemp)
for suff in dev test; do
    for name in data/libri_$suff/{enrolls2,trials_f2,trials_m2} \
        data/vctk_$suff/{enrolls_mic22,trials_f_common_mic22,trials_f_mic22,trials_m_common_mic22,trials_m_mic22}; do
        [ ! -f $name ] && echo "File $name does not exist" && exit 1
    done

    dset=data/libri_$suff
    eval_dset=$subdata/libri_$suff

    echo "${dset}"
    utils/subset_data_dir.sh --utt-list $dset/enrolls2 $dset ${eval_dset}_enrolls || exit 1
    cp $dset/enrolls2 ${eval_dset}_enrolls/enrolls || exit 1

    cut -d' ' -f2 $dset/trials_f2 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${eval_dset}_trials_f || exit 1
    cp $dset/trials_f2 ${eval_dset}_trials_f/trials || exit 1

    cut -d' ' -f2 $dset/trials_m2 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${eval_dset}_trials_m || exit 1
    cp $dset/trials_m2 ${eval_dset}_trials_m/trials || exit 1

    utils/combine_data.sh ${eval_dset}_trials_all ${eval_dset}_trials_f ${eval_dset}_trials_m || exit 1
    cat ${eval_dset}_trials_f/trials ${eval_dset}_trials_m/trials > ${eval_dset}_trials_all/trials

    dset=data/vctk_$suff
    eval_dset=$subdata/vctk_$suff
    utils/subset_data_dir.sh --utt-list $dset/enrolls_mic22 $dset ${eval_dset}_enrolls || exit 1
    cp $dset/enrolls_mic22 ${eval_dset}_enrolls/enrolls || exit 1

    cut -d' ' -f2 $dset/trials_f_mic22 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${eval_dset}_trials_f || exit 1
    cp $dset/trials_f_mic22 ${eval_dset}_trials_f/trials || exit 1

    cut -d' ' -f2 $dset/trials_f_common_mic22 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${eval_dset}_trials_f_common || exit 1
    cp $dset/trials_f_common_mic22 ${eval_dset}_trials_f_common/trials || exit 1

    # combine_data.sh <dest-data-dir> <src-data-dir> <src-data-dir2> ...
    utils/combine_data.sh ${eval_dset}_trials_f_all ${eval_dset}_trials_f ${eval_dset}_trials_f_common || exit 1
    cat ${eval_dset}_trials_f/trials ${eval_dset}_trials_f_common/trials > ${eval_dset}_trials_f_all/trials

    cut -d' ' -f2 $dset/trials_m_mic22 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${eval_dset}_trials_m || exit 1
    cp $dset/trials_m_mic22 ${eval_dset}_trials_m/trials || exit 1

    cut -d' ' -f2 $dset/trials_m_common_mic22 | sort | uniq > $temp
    utils/subset_data_dir.sh --utt-list $temp $dset ${eval_dset}_trials_m_common || exit 1
    cp $dset/trials_m_common_mic22 ${eval_dset}_trials_m_common/trials || exit 1

    utils/combine_data.sh ${eval_dset}_trials_m_all ${eval_dset}_trials_m ${eval_dset}_trials_m_common || exit 1
    cat ${eval_dset}_trials_m/trials ${eval_dset}_trials_m_common/trials > ${eval_dset}_trials_m_all/trials

    utils/combine_data.sh ${eval_dset}_trials_all ${eval_dset}_trials_f_all ${eval_dset}_trials_m_all || exit 1
    cat ${eval_dset}_trials_f_all/trials ${eval_dset}_trials_m_all/trials > ${eval_dset}_trials_all/trials
done
rm $temp

# echo "done"


# Anonymization configs
anon_level_trials="spk"                # spk (speaker-level anonymization) or utt (utterance-level anonymization)
anon_level_enroll="spk"                # spk (speaker-level anonymization) or utt (utterance-level anonymization)
cross_gender="false"                   # false (same gender xvectors will be selected) or true (other gender xvectors)
distance="plda"                        # cosine or plda
proximity="farthest"                   # nearest or farthest speaker to be selected for anonymization

anon_data_suffix=_anon

anoni_pool="libritts_train_other_500"

data_netcdf=$(realpath exp/am_nsf_data)   # directory where features for voice anonymization will be stored
mkdir -p $data_netcdf || exit 1;

# Chain model for BN extraction
ppg_model=exp/models/1_asr_am/exp
ppg_dir=${ppg_model}/nnet3_cleaned

# x-vector extraction
xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a
anon_xvec_out_dir=${xvec_nnet_dir}/anon
 
subdata=corpora/test_1_utt_list/data
# Anonymization
printf "${GREEN}\nStage 9: Anonymizing evaluation datasets...${NC}\n"
rand_seed=0
for dset in libri_dev_{enrolls,trials_f,trials_m} \
            vctk_dev_{enrolls,trials_f_all,trials_m_all} \
            libri_test_{enrolls,trials_f,trials_m} \
            vctk_test_{enrolls,trials_f_all,trials_m_all}; do
    # -z：判断字符串是否为空
    # 如果dset中不包含enroll，则输出的是空字符串，判空成立，执行then后面的操作
    if [ -z "$(echo $dset | grep enrolls)" ]; then
        anon_level=$anon_level_trials
        mc_coeff=$mc_coeff_trials
    else
        anon_level=$anon_level_enroll
        mc_coeff=$mc_coeff_enroll
    fi
    echo "anon_level = $anon_level"
    echo $dset
    printf "${GREEN}\nStage 9: Anonymizing using x-vectors and neural wavform models...${NC}\n"
    dset_dir=$subdata/$dset
    local/anon/anonymize_data_dir.sh \
        --nj $nj --anoni-pool $anoni_pool \
        --data-netcdf $data_netcdf \
        --ppg-model $ppg_model --ppg-dir $ppg_dir \
        --xvec-nnet-dir $xvec_nnet_dir \
        --anon-xvec-out-dir $anon_xvec_out_dir --plda-dir $xvec_nnet_dir \
        --pseudo-xvec-rand-level $anon_level --distance $distance \
        --proximity $proximity --cross-gender $cross_gender \
        --rand-seed $rand_seed \
        --anon-data-suffix $anon_data_suffix $dset_dir || exit 1;

    if [ -f $dset_dir/enrolls ]; then
      cp $dset_dir/enrolls $dset_dir$anon_data_suffix/ || exit 1
    else
      [ ! -f $dset_dir/trials ] && echo "File $dset_dir/trials does not exist" && exit 1
      cp $dset_dir/trials $dset_dir$anon_data_suffix/ || exit 1
    fi
    rand_seed=$((rand_seed+1))
done

echo "step 1 finished!"