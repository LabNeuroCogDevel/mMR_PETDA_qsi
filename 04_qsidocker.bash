#!/usr/bin/env bash

#
# run dockerized qsiprep
#  optional input arg: qsiprep version
#    ./runme_docker.bash 0.6.4-1
#  (default to latest, saves outputfolder with yyyymmdd date)
#

set -euo pipefail

# what docker image to use. e.g. latest
# can be given as first argument to runme_docker.bash
# e.g. ./runme_docker.bash 0.6.4-1
[ $# -ne 1 ] && label='0.6.5' || label="$1"

if [[ $label =~ '0.6.5'|latest ]]; then
   docker pull pennbbl/qsiprep:$label || continue
   prefix="docker-$label-$(docker inspect -f '{{ .Created }}' pennbbl/qsiprep)"
else
   prefix="docker-$label"
fi

# remove directoires if we have them
for d in /Volumes/Hera/Projects/mMR_PETDA/qsi/out/{,workdir-}$prefix; do
   [ -r $d ] && rm -r $d;
done

docker run --rm -it \
   -v $FREESURFER_HOME:$FREESURFER_HOME:ro \
   -v /Volumes:/Volumes:ro \
   -v /Volumes/Hera/Projects/mMR_PETDA/qsi/BIDS_TEST_V2_FMP:/data:ro \
   -v /Volumes/Hera/Projects/mMR_PETDA/qsi/out:/out \
   pennbbl/qsiprep:$label \
     --fs-license-file  $FREESURFER_HOME/license.txt \
     --output-resolution 2.3 \
     --hmc-model 3dSHORE \
     --stop-on-first-crash \
     -w /out/workdir-$prefix \
     /data \
     /out/$prefix  \
     participant

     `#--b0-to-t1w-transform Affine` \
     `#--force-syn` \

