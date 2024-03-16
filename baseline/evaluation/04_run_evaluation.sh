#!/bin/bash
# Extract of Voice-Privacy-Challenge-2020/baseline/run.sh
#
# License of the original script:
# Copyright (C) 2020  <Brij Mohan Lal Srivastava, Natalia Tomashenko, Xin Wang, Jose Patino, Paul-Gauthier Noé, Andreas Nautsch, ...>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#


set -e

#===== begin config =======

nj=$(nproc)
mcadams=false
stage=0
gpu=0

vp_dir=/data/yh/Voice-Privacy-Challenge-2020/baseline
cd $vp_dir

printf -v results '%(%Y-%m-%d-%H-%M-%S)T' -1
results=exp/result/results-$results

# Chain model for ASR evaluation
asr_eval_model=exp/models/asr_eval

# ASV_eval config
asv_eval_model=exp/models/asv_eval/xvect_01709_1
plda_dir=${asv_eval_model}/xvect_train_clean_360

anon_data_suffix=_anon

. utils/parse_options.sh || exit 1;

. path.sh
. cmd.sh


# if [[ $gpu != 'cpu' ]]; then
export CUDA_VISIBLE_DEVICES=$gpu
export CURRENNT_CUDA_DEVICE=$gpu
# fi

#=========== end config ===========


if [ $stage -le 11 ]; then
  printf "${GREEN}\nStage 11: Evaluate datasets using speaker verification...${NC}\n"
  for suff in test; do
    # printf "${RED}**ASV: libri_${suff}_trials_f, enroll - original, trial - original**${NC}\n"
    # local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    #   --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_f --results $results || exit 1;
    # printf "${RED}**ASV: libri_${suff}_trials_f, enroll - original, trial - anonymized**${NC}\n"
    # local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    #   --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_f$anon_data_suffix --results $results || exit 1;
    # printf "${RED}**ASV: libri_${suff}_trials_f, enroll - anonymized, trial - anonymized**${NC}\n"
    # local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    #   --enrolls libri_${suff}_enrolls$anon_data_suffix --trials libri_${suff}_trials_f$anon_data_suffix --results $results || exit 1;

    # printf "${RED}**ASV: libri_${suff}_trials_m, enroll - original, trial - original**${NC}\n"
    # local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    #   --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_m --results $results || exit 1;
    # printf "${RED}**ASV: libri_${suff}_trials_m, enroll - original, trial - anonymized**${NC}\n"
    # local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    #   --enrolls libri_${suff}_enrolls --trials libri_${suff}_trials_m$anon_data_suffix --results $results || exit 1;
    # printf "${RED}**ASV: libri_${suff}_trials_m, enroll - anonymized, trial - anonymized**${NC}\n"
    # local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
    #   --enrolls libri_${suff}_enrolls$anon_data_suffix --trials libri_${suff}_trials_m$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_f, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_f$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_m, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_m$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f_common --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_f_common$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_f_common, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_f_common$anon_data_suffix --results $results || exit 1;

    printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - original, trial - original**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m_common --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - original, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls --trials vctk_${suff}_trials_m_common$anon_data_suffix --results $results || exit 1;
    printf "${RED}**ASV: vctk_${suff}_trials_m_common, enroll - anonymized, trial - anonymized**${NC}\n"
    local/asv_eval.sh --plda_dir $plda_dir --asv_eval_model $asv_eval_model \
      --enrolls vctk_${suff}_enrolls$anon_data_suffix --trials vctk_${suff}_trials_m_common$anon_data_suffix --results $results || exit 1;
  done
fi

echo "pwd:$PWD"
subdata=corpora/test_1_utt_list/data

# Make ASR evaluation subsets
# if [ $stage -le 12 ]; then
#   printf "${GREEN}\nStage 12: Making ASR evaluation subsets...${NC}\n"
#   for suff in dev test; do
#     for name in $subdata/libri_${suff}_{trials_f,trials_m} $subdata/libri_${suff}_{trials_f,trials_m}$anon_data_suffix \
#         $subdata/vctk_${suff}_{trials_f_all,trials_m_all} $subdata/vctk_${suff}_{trials_f_all,trials_m_all}$anon_data_suffix; do
#       [ ! -d $name ] && echo "Directory $name does not exist" && exit 1
#     done
#     utils/combine_data.sh $subdata/libri_${suff}_asr $subdata/libri_${suff}_{trials_f,trials_m} || exit 1
#     utils/combine_data.sh $subdata/libri_${suff}_asr$anon_data_suffix $subdata/libri_${suff}_{trials_f,trials_m}$anon_data_suffix || exit 1
#     utils/combine_data.sh $subdata/vctk_${suff}_asr $subdata/vctk_${suff}_{trials_f_all,trials_m_all} || exit 1
#     utils/combine_data.sh $subdata/vctk_${suff}_asr$anon_data_suffix $subdata/vctk_${suff}_{trials_f_all,trials_m_all}$anon_data_suffix || exit 1
#   done
# fi


if [ $stage -le 12 ]; then
  printf "${GREEN}\nStage 12: Making ASR evaluation subsets...${NC}\n"
  for suff in test; do
    for name in $subdata/vctk_${suff}_{trials_f_all,trials_m_all} $subdata/vctk_${suff}_{trials_f_all,trials_m_all}$anon_data_suffix; do
      [ ! -d $name ] && echo "Directory $name does not exist" && exit 1
    done
    utils/combine_data.sh $subdata/vctk_${suff}_asr $subdata/vctk_${suff}_{trials_f_all,trials_m_all} || exit 1
    utils/combine_data.sh $subdata/vctk_${suff}_asr$anon_data_suffix $subdata/vctk_${suff}_{trials_f_all,trials_m_all}$anon_data_suffix || exit 1
  done
fi

# Performing intelligibility assessment using ASR decoding
if [ $stage -le 13 ]; then
  for dset in vctk; do
    for suff in test; do
      for data in ${dset}_${suff}_asr ${dset}_${suff}_asr$anon_data_suffix; do
        printf "${GREEN}\nStage 13: Performing intelligibility assessment using ASR decoding on $dset...${NC}\n"
        local/asr_eval.sh --nj $nj --dset $data --model $asr_eval_model --results $results || exit 1;
      done
    done
  done
fi

# Collecting results
if [ $stage -le 14 ]; then
  printf "${GREEN}\nStage 14: Collecting results${NC}\n"
  expo=$results/results.txt
  for name in `find $results -type d -name "ASV-*" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    [ ! -f $name/EER ] && echo "Directory $name/EER does not exist" && exit 1
    #for label in 'EER:' 'minDCF(p-target=0.01):' 'minDCF(p-target=0.001):'; do
    for label in 'EER:'; do
      value=$(grep "$label" $name/EER)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/Cllr ] && echo "Directory $name/Cllr does not exist" && exit 1
    for label in 'Cllr (min/act):' 'ROCCH-EER:'; do
      value=$(grep "$label" $name/Cllr)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/linkability_log ] && echo "Directory $name/linkability_log does not exist" && exit 1
    for label in 'linkability:'; do
      value=$(grep "$label" $name/linkability_log)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
    [ ! -f $name/zebra ] && echo "Directory $name/zebra does not exist" && exit 1
    for label in 'Population:' 'Individual:'; do
      value=$(grep "$label" $name/zebra)
      value=$(echo $value)
      echo "  $value" | tee -a $expo
    done
  done
  for name in `find $results -type f -name "ASR-*" | sort`; do
    echo "$(basename $name)" | tee -a $expo
    while read line; do
      echo "  $line" | tee -a $expo
    done < $name
  done
fi

# Compute the de-indentification and the voice-distinctiveness preservation with the similarity matrices
if [ $stage -le 15 ]; then
   printf "${GREEN}\nStage 15: Compute the de-indentification and the voice-distinctiveness preservation with the similarity matrices${NC}\n"
   for suff in test; do
        for data in vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do

      # for data in libri_${suff}_trials_f libri_${suff}_trials_m vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
         printf "${BLUE}\nStage 15: Compute the de-indentification and the voice-distinctiveness for $data${NC}\n"
         local/similarity_matrices/compute_similarity_matrices_metrics.sh --asv_eval_model $asv_eval_model --plda_dir $plda_dir --set_test $data --results $results || exit 1;
     done
   done
fi

# Collecting results for re-indentification and the voice-distinctiveness preservation
if [ $stage -le 16 ]; then
   printf "${GREEN}\nStage 16: Collecting results for re-indentification and the voice-distinctiveness preservation${NC}\n"
  expo=$results/results.txt
  dir="similarity_matrices_DeID_Gvd"
  for suff in test; do
       for name in vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
    #  for name in libri_${suff}_trials_f libri_${suff}_trials_m vctk_${suff}_trials_f vctk_${suff}_trials_m vctk_${suff}_trials_f_common vctk_${suff}_trials_m_common; do
       echo "$name" | tee -a $expo
	   echo $results/$dir/$name/DeIDentification
       [ ! -f $results/$dir/$name/DeIDentification ] && echo "File $results/$dir/$name/DeIDentification does not exist" && exit 1
       label='De-Identification :'
       value=$(grep "$label" $results/$dir/$name/DeIDentification)
       value=$(echo $value)
       echo "  $value" | tee -a $expo
	   [ ! -f $results/$dir/$name/gain_of_voice_distinctiveness ] && echo "File $name/gain_of_voice_distinctiveness does not exist" && exit 1
       label='Gain of voice distinctiveness :'
       value=$(grep "$label" $results/$dir/$name/gain_of_voice_distinctiveness)
       value=$(echo $value)
       echo "  $value" | tee -a $expo
     done
  done
fi

if [ $stage -le 17 ]; then
  printf "${GREEN}\nStage 17: Summarizing ZEBRA plots for all experiments${NC}\n"
  mkdir -p voiceprivacy-challenge-2020
  PYTHONPATH=$(realpath ../zebra) python ../zebra/voiceprivacy_challenge_plots.py || exit 1
fi
