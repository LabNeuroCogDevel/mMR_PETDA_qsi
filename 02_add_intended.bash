#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

# 1) renames and phase1 to phasediff
# 2) add EchoTime1, EchoTime2, and intendedFor to the fmap closest to dwi
# uses output of dwi-mmr-fm.R: txt/best_T1w_for_dwi.txt
# 
#  20191126WF  init

BIDSDIR="BIDS_FMP"

# take header off text file
# 
#id                   	dwi    	run         	acqtime   	acqdiff        	n_ses_fmap
#sub-10195_ses-20170824	59970.1	run-1acq-dwi	59232.8525	737.247499999998	3
sed 1d txt/best_fmap_for_dwi.txt |
 while read id dwi runacq t d n; do
    sesdir=$BIDSDIR/${id/_/\/}
    [ ! -d $sesdir ] && echo "no ses dir for $id?!" && break
    [ ! -d $sesdir ] && echo "no ses dir for $id?!" && continue
    ! [[ $runacq =~ (run-[0-9]+)(acq-.*) ]] && echo "run '$run' doesnt look like 'run-#acq-.*'" && continue
    run=${BASH_REMATCH[1]}
    acq=${BASH_REMATCH[2]}

    # relative to bidsRoot
    theDSI=$(cd $BIDSDIR; find ${id/_/\/}/dwi/ -iname *nii.gz)
    [ -z "$theDSI" -o ! -r "$BIDSDIR/$theDSI" ] && echo "cannot find the dsi image for $sesdir/dwi: '$theDSI'" && continue

    # phase1 files should be called phasediff
    rename  's/_phase1\./_phasediff./' $sesdir/fmap/*phase1.*

    # find the phasediff that matches what R found
    phasediff=$(find $sesdir/fmap -iname "*$acq*$run*phasediff.json")
    # must exist
    [ -z $phasediff -o ! -r "$phasediff" ] &&
       echo "no phasediff like $sesdir/fmap/*$acq*$run*phasediff.json" && continue

    # can skip if already have "IntendedFor"
    grep -q IntendedFor $phasediff && echo "# already run on $phasediff" && continue

    # add it
    # replace the first { in the file with the 3 new lines we need:
    #  EchoTime1, EchoTime2, and IntendedFor (file relative to BIDSROOT)
    sed -i 's;^{;{\n\t"EchoTime1": 0.00492,\n\t"EchoTime2": 0.00738,\n\t"IntendedFor":["'"${theDSI/.nii.gz/}"'"],;' $phasediff
    echo "added Echo1+2, '$theDSI' to $phasediff"
    # TODO: get Echo1 and Echo2 from mag1 and mag2 ?
    # read E1 E2 <<< $(jq .EchoTime $sesdir/fmap/*$acq*$run*magnitude[12].json|tr '\n' ' ')
 done

