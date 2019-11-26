
# raw files
DWI=$(wildcard BIDS_FMP/sub-*/ses-*/dwi/*nii.gz) 
FMAP=$(wildcard BIDS_FMP/sub-*/ses-*/fmap/*json)
ANAT=$(wildcard BIDS_FMP/sub-*/ses-*/anat/*nii.gz)

# clear all buildtin
.SUFFIXES:

# final output is from running qsiprep
.PHONY: all
all: .make/qsiprep.ls

# pick which files to use
txt/best_fmap_for_dwi.txt: 01_dwi-mmr-fm.R ${DWI} ${FMAP}
	./01_dwi-mmr-fm.R
txt/best_T1w_for_dwi.txt: 01_dwi-mmr-t1.R ${DWI} ${ANAT}
	./01_dwi-mmr-t1.R

# rename and modify json
.make/phasediff.ls: 02_add_intended.bash txt/best_fmap_for_dwi.txt
	./02_add_intended.bash
	mkls $@ 'BIDS_FMP/sub-*/ses-*/fmap/*_phasediff.json'

# remove unused mag and t1 files
.make/intended_only.ls: txt/best_T1w_for_dwi.txt .make/phasediff.ls
	./03_remove_extra.bash
	mkls $@ BIDS_FMP/sub-*/ses-*/anat/*.nii.gz BIDS_FMP/sub-*/ses-*/fmap/*.nii.gz

# actually run qsiprep
.make/qsiprep.ls: .make/intended_only.ls
	./04_qsidocker.bash
	# maybe just touch the file?
	mkstat $@ 'out/*'
