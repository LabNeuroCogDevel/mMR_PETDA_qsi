#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

source funcs.src.bash # BIDSDIR, matchrow_to_ses(), rmnot()

#
# remove extra mag and t1 images
#  20191203WF  rm if empty fmap, anat, or dwi
#  20191126WF  init

#id                   	dwi    	run         	acqtime   	acqdiff        	n_ses_fmap
#sub-10195_ses-20170824	59970.1	run-1acq-dwi	59232.8525	737.247499999998	3
sed 1d txt/best_fmap_for_dwi.txt | while read id j runacq j; do
   read sesdir acq run <<<$(matchrow_to_ses "$id" "$runacq")
   [ -z "$sesdir" ] && continue

   #echo "sesdir: $sesdir"
   # remove files not like the ideal acq run
   rmnot $sesdir/fmap "*$acq*$run*" || continue
done

sed 1d txt/best_T1w_for_dwi.txt | while read id j runacq j; do
   read sesdir acq run <<<$(matchrow_to_ses "$id" "$runacq")
   [ -z "$sesdir" ] && continue

   # remove files not like the ideal acq run
   rmnot $sesdir/anat "*$acq*$run*" || continue
done

## remove if missing necessary files
missing_nii(){
  [ $(find $1 -iname '*.nii.gz' | wc -l) -ne 0 ] && return 1
  echo "no nii in $d" >&2
  return 0
}
for d in $BIDSDIR/sub-*/ses-*; do
   missing_nii $d/anat/ && rm -r $d && continue
   missing_nii $d/fmap/ && rm -r $d && continue
   missing_nii $d/dwi/  && rm -r $d && continue
done
