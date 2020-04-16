#!/usr/bin/env bash
set -x
#
# run dockerized qsiprep
#  optional input arg: qsiprep version
#    ./runme_docker.bash 0.6.4-1
#  (default to latest, saves outputfolder with yyyymmdd date)
#
RES=2 # upsampling from 2.3 !

set -euo pipefail
cd $(dirname $0)
#source funcs.src.bash 
env |grep -q "^BIDSDIR=" || BIDSDIR="DWI_BIDS_noses"
[ -z "$BIDSDIR" -o ! -d "$BIDSDIR" ] && echo "NO BIDSDIR '$BIDSDIR'" &>2 && exit 1
echo "USING BIDSDIR: $BIDSDIR"

# what docker image to use. e.g. latest
# can be given as first argument to runme_docker.bash
# run like:
# ./runme_docker.bash latest
[ $# -eq 0 ] && label='latest' || label="$1"  # prev stable run: 0.6.5
echo "qsiprep label: $label"

# latest and unstable are moving targets
# pull them each time we try to run - and label with date
#prefix=$(date +%F-%T-)
# 20200108 - remove timestamp b/c we have list of subjects
# 20200128 - pull prefix from environment or set to empty
env | grep -q ^QSIPREFIX= && prefix="$QSIPREFIX" || prefix=""

[ -z "$prefix" ] && prefix="."

# 20200416 - if we're rerunning for matt, change the resolution not to upsample
[[ "$prefix" =~ for_matt ]]  && RES=2.3 && echo "SETTING RES to $RES"

if [[ $label =~ unstable|latest ]]; then
   docker pull pennbbl/qsiprep:$label || continue
   prefix="$prefix/docker-$label-$(docker inspect -f '{{ .Created }}' pennbbl/qsiprep)"
else
   prefix="$prefix/docker-$label"
fi

if [ $# -gt 1 ]; then
   shift;
   sublist="--participant-label $@" 
   # if we have fewer than 10, label prefix with the subjs
   if [ $# -lt 10 ] ; then
      list="$@"
      list="${list// /_}"
      list="${list//sub-/_}"
      list="${list//__/_}"
      prefix="$prefix-$list"
   # otherwise just put the number
   # assume QSIPREFIX will distinguish
   else
      prefix="$prefix-${RES}mm-$#"
   fi
   # TODO: maybe change to 1
   ncpu="--n-cpus 2"
else
   sublist=""
   # TODO: maybe change to empty? to 16?
   ncpu="--n-cpus 2"
fi

# # remove directoires if we have them
# for d in /Volumes/Hera/Projects/mMR_PETDA/qsi/out/{,workdir-}$prefix; do
#    [ -r $d ] && rm -r $d;
# done

# skip if already run
# e.g. /out/workdir/skullstrip/docker-0.6.5-1122820190418
test -d /out/workdir/$prefix && echo "have; rm $_ # to redo" && exit 0

set -x
docker run --rm \
   -v $FREESURFER_HOME:$FREESURFER_HOME:ro \
   -v /Volumes:/Volumes:ro \
   -v /Volumes/Hera/Projects/mMR_PETDA/qsi/$BIDSDIR:/data:ro \
   -v /Volumes/Hera/Projects/mMR_PETDA/qsi/out:/out \
   pennbbl/qsiprep:$label \
   /data \
   /out/$prefix \
   participant \
     --fs-license-file  $FREESURFER_HOME/license.txt \
     --output-resolution $RES \
     --hmc-model 3dSHORE \
     $sublist \
     $ncpu \
     -w /out/workdir/$prefix \

     #--stop-on-first-crash \
