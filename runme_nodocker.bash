#!/usr/bin/env bash
set -euo pipefail
echo "## using $(which qsiprep) @ $(qsiprep --version)"

# what to call this run
prefix="trunc-nocompress-$(qsiprep --version|sed 's/ //;s/qsiprep//;')"

# remove any previous attempt with this prefix
#for d in out/{workdir,qsiprep}-$prefix/; do [ -e $d ] && rm -r $d; done
# instead die if we have already run with this prefix
for d in out/{workdir,qsiprep}-$prefix/; do [ -e $d ] && echo "already have $d! change 'prefix=' in $0" && exit 1; done

# actually run it
# N.B. qsiprep installed with pip from editted source @
#      /Volumes/Hera/Projects/mMR_PETDA/qsi
export AFNI_COMPRESSOR=""
qsiprep \
   --output-resolution 2.3 \
   --skip-bids-validation \
   --fs-license-file  $FREESURFER_HOME/license.txt \
   -w out/workdir-$prefix  \
   --hmc-model 3dSHORE \
   --stop-on-first-crash \
   BIDS_TEST/ \
   out/qsiprep-$prefix \
   participant \

