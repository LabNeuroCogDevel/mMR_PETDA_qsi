#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
SCRIPTDIR="$(cd $(dirname "$0"); pwd)"

#
# collapse sub-xxx/ses-yyy to sub-xxx_yyyy
# so we are not merging T1s across session
#
# 20191216WF - init
#

find DWI_BIDS_all/ -type f,l|while read old; do
 new=$old
 # from
 #   DWI_BIDS_all/sub-10843/ses-20170605/anat/sub-10843_ses-20170605_acq-1ADNIG2_run-1_T1w.json
 # to
 #   DWI_BIDS_noses/sub-1084320170605/anat/sub-1084320170605_acq-1ADNIG2_run-1_T1w.json

 new=${new/DWI_BIDS_all/DWI_BIDS_noses} # change root directory
 new=${new//[\/_]ses-/} # remove /ses- and _ses- 
 # done if already exists
 [ -r $new ] && continue

 # otherwise link in to possibly a new directory
 ndir=$(dirname $new)
 [ ! -d $ndir ] && mkdir -p $ndir
 [[ $new =~ phasediff.json ]] &&
   sed 's:ses-[0-9]\+/\|_ses-::g' $old > $new ||
   ln -s $(pwd)/$old $new
done

