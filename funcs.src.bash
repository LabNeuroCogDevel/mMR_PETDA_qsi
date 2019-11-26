BIDSDIR="BIDS_FMP"

warn(){ echo -e $@ >&2; }
matchrow_to_ses() {
   # input: id, "runacq" like "run-1acq-1ADNI"
   # output: BIDS sesion folder, run, acq
   # process row from e.g. txt/best_T1w_for_dwi.txt
   #     id                    	dwi        	run         	acqtime  	acqdiff        	n_ses_T1w
   #     sub-10843_ses-20170605	56194.8925	run-1acq-1ADNI	55572.805	622.087500000001	1
   # or txt/best_fmap_for_dwi.txt
   #     sub-10195_ses-20170824	59970.1  	run-1acq-dwi  	59232.8525	737.247499999998	3
   id="$1"; shift
   runacq="$1"; shift

   sesdir=$BIDSDIR/${id/_/\/}
   [ ! -d $sesdir ] && warn "no ses dir for $id?!" && return 1
   ! [[ $runacq =~ (run-[0-9]+)(acq-.*) ]] && warn "run '$run' doesnt look like 'run-#acq-.*'" && continue
   run=${BASH_REMATCH[1]}
   acq=${BASH_REMATCH[2]}
   echo "$sesdir $acq $run"
}

MAXREMOVE=25
rmnot() {
   # remove all files in a directory that are not like a 'patt'
   # does some checks to make sure something will still exist 
   # and that not too many files are removed 
   d="$1"; shift
   patt="$1"; shift
   dryrun=""
   #dryrun="echo"

   nkeep=$(find  $d -maxdepth 1 -type f,l -iname "$patt" | wc -l)
   nrm=$(find $d -type f,l -not -iname "$patt" | wc -l)
   [ $nkeep -eq 0 ] && 
      warn "'$d/$patt' matches nothing; not deleted all others (ie. everything)" && return 1
   [ $nrm -eq 0 ] && echo "# have only the $nkeep files matching '$patt' in $d" && return 0
   [ $nrm -gt $MAXREMOVE ] && echo "# want to remove >$MAXREMOVE ($nrm) in $d (not '$patt'); skipping!" && return 1
   echo "keeping $nkeep '$d/$patt'; rming $nrm"
   find $d -type f,l -not -iname "$patt" -exec $dryrun rm {} \+
}
