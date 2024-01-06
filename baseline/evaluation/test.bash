data_dir=corpora/data/utt_list/libri_test_enroll
# dset=$(echo $data_dir | awk -F'/' '{print $NF}')
# echo "dset=$dset"
echo "$(basename $data_dir)"