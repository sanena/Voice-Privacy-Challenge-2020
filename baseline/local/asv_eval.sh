#!/bin/bash

set -e

. ./cmd.sh
. ./path.sh

nj=$(nproc)
# 说话人验证模型路径
asv_eval_model=exp/models/asv_eval/xvect_01709_1
plda_dir=$asv_eval_model/xvect_train_clean_360

#enrolls=vctk_dev_enrolls
#trials=vctk_dev_trials_f_common
# 数据集
enrolls=libri_dev_enrolls
trials=libri_dev_trials_f
# data_dir=data
# data_dir=corpora/test_utt_list_2/data
data_dir=corpora/data/utt_list

# 保存结果的路径
printf -v time '%(%Y-%m-%d-%H-%M-%S)T' -1
results=exp/results-$time

. ./utils/parse_options.sh

for name in $asv_eval_model/final.raw $plda_dir/plda $plda_dir/mean.vec \
    $plda_dir/transform.mat $data_dir/$enrolls/enrolls $data_dir/$trials/trials ; do
  [ ! -f $name ] && echo "File $name does not exist" && exit 1
done

# 计算MFCC和VAD
for dset in $enrolls $trials; do
  data=$data_dir/$dset
  # data=data/$dset
  spk2utt=$data/spk2utt
  [ ! -f $spk2utt ] && echo "File $spk2utt does not exist" && exit 1
  num_spk=$(wc -l < $spk2utt)
  njobs=$([ $num_spk -le $nj ] && echo $num_spk || echo $nj)
  if [ ! -f $data/.done_mfcc ]; then
    printf "${RED}  compute MFCC: $dset${NC}\n"
    steps/make_mfcc.sh --nj $njobs --cmd "$train_cmd" \
      --write-utt2num-frames true $data || exit 1
    utils/fix_data_dir.sh $data || exit 1
    touch $data/.done_mfcc
  fi
  if [ ! -f $data/.done_vad ]; then
    printf "${RED}  compute VAD: $dset${NC}\n"
    sid/compute_vad_decision.sh --nj $njobs --cmd "$train_cmd" $data || exit 1
    utils/fix_data_dir.sh $data || exit 1
    touch $data/.done_vad
  fi
done

# 计算x-vector
for dset in $enrolls $trials; do
  data=$data_dir/$dset
  # data=data/$dset
  spk2utt=$data/spk2utt
  [ ! -f $spk2utt ] && echo "File $spk2utt does not exist" && exit 1
  num_spk=$(wc -l < $spk2utt)
  njobs=$([ $num_spk -le $nj ] && echo $num_spk || echo $nj)
  expo=$asv_eval_model/xvect_$dset
  if [ ! -f $expo/.done ]; then
    printf "${RED}  compute x-vect: $dset${NC}\n"
    sid/nnet3/xvector/extract_xvectors.sh --nj $njobs --cmd "$train_cmd" \
      $asv_eval_model $data $expo || exit 1
    touch $expo/.done
  fi
done

expo=$results/ASV-$enrolls-$trials
if [ ! -f $expo/.done ]; then
  printf "${RED}  ASV scoring: $expo${NC}\n"
  mkdir -p $expo
  xvect_enrolls=$asv_eval_model/xvect_$enrolls/xvector.scp
  xvect_trials=$asv_eval_model/xvect_$trials/xvector.scp
  for name in $xvect_enrolls $xvect_trials; do
    [ ! -f $name ] && echo "File $name does not exist" && exit 1
  done
  # $train_cmd=run.pl，在bash环境中执行以下命令，并将日志输出到$expo/log/ivector-plda-scoring.log文件中
  # sed工具，用正则表达式'-r'匹配输入文件中的下划线和短横线，将他们替换成空格，‘/g’表示全局替换
  # awk，对输入进程处理
  #   split($1, val, "_")，对每一行的第一个字段（以空格分割）进行拆分，以下划线作为分割符，拆分的结果存储在数组‘val’中
  #   ++num[val[1]]，对以val[1]（说话者ID）为索引的数组num中的元素进行递增操作，即统计每个val[1]出现的次数
  #   END{for (spk in num) print spk, num[spk]}, 在处理完所有行之后，执行此快。遍历打印每个索引（'spk'）及其出现的次数。
  # ivector-plda-scoring, 用于进行ivector-plda识别评分的命令。
  #   它接受之前的输出作为输入，包括一系列的ivector处理和标准化，最终输出到$expo/scores'文件中，如果执行失败，脚本将推出并返回错误代码1
  $train_cmd $expo/log/ivector-plda-scoring.log \
    sed -r 's/_|-/ /g' $data_dir/$enrolls/enrolls \| awk '{split($1, val, "_"); ++num[val[1]]}END{for (spk in num) print spk, num[spk]}' \| \
      ivector-plda-scoring --normalize-length=true --num-utts=ark:- \
        "ivector-copy-plda --smoothing=0.0 $plda_dir/plda - |" \
        "ark:cut -d' ' -f1 $data_dir/$enrolls/enrolls | grep -Ff - $xvect_enrolls | ivector-mean ark:$data_dir/$enrolls/spk2utt scp:- ark:- | ivector-subtract-global-mean $plda_dir/mean.vec ark:- ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
        "ark:cut -d' ' -f2 $data_dir/$trials/trials | sort | uniq | grep -Ff - $xvect_trials | ivector-subtract-global-mean $plda_dir/mean.vec scp:- ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
        "cat $data_dir/$trials/trials | cut -d' ' --fields=1,2 |" $expo/scores || exit 1
  
  eer=`compute-eer <(local/prepare_for_eer.py $data_dir/$trials/trials $expo/scores) 2> /dev/null`
  mindcf1=`sid/compute_min_dcf.py --p-target 0.01 $expo/scores $data_dir/$trials/trials 2> /dev/null`
  mindcf2=`sid/compute_min_dcf.py --p-target 0.001 $expo/scores $data_dir/$trials/trials 2> /dev/null`

  # tee将标准输出写入文件，并同时显示在终端上，-a表示在文件末尾追加
  echo "EER: $eer%" | tee $expo/EER
  echo "minDCF(p-target=0.01): $mindcf1" | tee -a $expo/EER
  echo "minDCF(p-target=0.001): $mindcf2" | tee -a $expo/EER
  PYTHONPATH=$(realpath ../cllr) python ../cllr/compute_cllr.py \
    -k $data_dir/$trials/trials -s $expo/scores -e | tee $expo/Cllr || exit 1

  # Compute linkability
  PYTHONPATH=$(realpath ../anonymization_metrics) python local/scoring/linkability/compute_linkability.py \
    -k $data_dir/$trials/trials -s $expo/scores \
    -d -o $expo/linkability | tee $expo/linkability_log || exit 1

  # Zebra
  label=$enrolls-$trials
  PYTHONPATH=$(realpath ../zebra) python ../zebra/zero_evidence.py \
    -k $data_dir/$trials/trials -s $expo/scores -l $label | tee $expo/zebra || exit 1
    # -k $data_dir/$trials/trials -s $expo/scores -l $label -e png | tee $expo/zebra || exit 1

  touch $expo/.done
fi
