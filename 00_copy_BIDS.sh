#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)
source funcs.src.bash # BIDSDIR="DWI_BIDS_all"
#
# copy from pet bids specifically for qsiprep
# copy because json will be modified and some files will be removed
#  20191203WF  init

ORIGBIDS=/Volumes/Hera/Raw/BIDS/mMRDA-dev/
find $ORIGBIDS -type f,l \
   \( -iname '*.nii.gz' -or -iname '*.json' \) \
   \( -ipath '*/anat/*' -or -ipath '*/fmap/*' -or -ipath '*/dwi/*' \) > txt/BIDS_filelist.txt

rsync -vhiLr /Volumes/Hera/Raw/BIDS/mMRDA-dev/ $BIDSDIR \
      --files-from=<( sed "s:^$ORIGBIDS::" txt/BIDS_filelist.txt )
