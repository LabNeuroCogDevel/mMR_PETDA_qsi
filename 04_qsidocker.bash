#!/usr/bin/env bash
set -euo pipefail

# defaults
# 20200521 - RES changed at somepoint from default of 2mm
env |grep -q "^RES=" || RES=2.3 # upsampling from 2.3 ! -- if prefix=for_matt, will force 2.3
env |grep -q "^BIDSDIR=" || BIDSDIR="DWI_BIDS_noses"
env |grep -q ^QSIPREFIX= && prefix="$QSIPREFIX" || prefix=""
env |grep -q ^QSI_NCPU= && QSI_NCPU="$QSI_NCPU" || QSI_NCPU=2
env |grep -q ^DRYRUN= && DRYRUN=echo || DRYRUN=""

# USAGE
USAGE(){
   cat <<HEREDOC 
   $0 - run qsiprep with docker"
   USAGE:
    [env] $0 [label subjects]
    env options: RES QSI_NCPU QSIPREFIX DRYRUN BIDSDIR 
    label e.g.: latest 0.6.5
   Example:
    $0                                           # this message
    $0 latest                                    # run all with latest
    QSIPREFIX="for_matt" $0 latest               # all with different prefix
    $0 latest 1122820190418                      # just 1122820190418
    QSIPREFIX="for_matt" $0 latest 1122820190418 # just one but with different prefix
   Defaults:
     RES=$RES QSI_NCPU=$QSI_NCPU QSIPREFIX="$QSIPREFIX" BIDSDIR="$BIDSDIR"
   Notes:
     QSIPREFIX="for_matt" is a special. forces resolution to iso 2.3 
     label 'latest' is always the newest stable docker
     label 'unstable' is the most recent
      if using either latest or unstable, prefix will be appending with the docker image creation time
      see \`docker inspect -f '{{ .Created }}' pennbbl/qsiprep\`
HEREDOC

exit 1
}

#
# run dockerized qsiprep
#  optional input arg: qsiprep version
#    ./runme_docker.bash 0.6.4-1
#  (default to latest, saves outputfolder with yyyymmdd date)
#

cd $(dirname $0)

# what docker image to use. e.g. latest
# can be given as first argument to runme_docker.bash
# run like:
# ./runme_docker.bash latest
[ $# -eq 0 ] && USAGE # exit 1
[[ $1 =~ help|-h ]] && USAGE

[ -z "$BIDSDIR" -o ! -d "$BIDSDIR" ] && echo "NO BIDSDIR '$BIDSDIR'" &>2 && exit 1

# show what we are doing
echo "USING settings:"
env |grep -e '^(QSIPREFIX|RES|QSI_NCPU|BIDSDIR)='

label="$1"  # prev stable run: 0.6.5
echo "qsiprep label: $label"

# latest and unstable are moving targets
# pull them each time we try to run - and label with date
#prefix=$(date +%F-%T-)
# 20200108 - remove timestamp b/c we have list of subjects
# 20200128 - pull prefix from environment or set to empty

[ -z "$prefix" ] && prefix="."

# 20200416 - if we're rerunning for matt, change the resolution not to upsample
[[ "$prefix" =~ for_matt ]]  && RES=2.3 && echo "SETTING RES to $RES"

if [[ $label =~ unstable|latest ]]; then
   docker pull pennbbl/qsiprep:$label || continue
   prefix="$prefix/docker-$label-$(docker inspect -f '{{ .Created }}' pennbbl/qsiprep)"
else
   prefix="$prefix/docker-$label"
fi


# if we have more than one input argument (right side of script)
# use those arguments as participant labels
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
else
   sublist=""
fi

# # remove directoires if we have them
# for d in /Volumes/Hera/Projects/mMR_PETDA/qsi/out/{,workdir-}$prefix; do
#    [ -r $d ] && rm -r $d;
# done

# skip if already run
# e.g. /out/workdir/skullstrip/docker-0.6.5-1122820190418
test -d /out/workdir/$prefix && echo "have; rm $_ # to redo" && exit 0

set -x
$DRYRUN docker run --rm \
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
     --n-cpus $QSI_NCPU \
     -w /out/workdir/$prefix \

     #--stop-on-first-crash \
