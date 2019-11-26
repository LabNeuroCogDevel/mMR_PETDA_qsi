#!/usr/bin/env Rscript
library(dplyr)
library(lubridate)
library(tidyr)

# extract acquistiontime from all the relevant json sidecar files 
# extract id+session, dwi (".") or run number (run-1), and acq time
cmd <- "
 find  /Volumes/Hera/Raw/BIDS/mMRDA-dev/ -iname '*phase1*.json' -or -iname '*dwi.json' |
 while read f; do 
   jq .AcquisitionTime < $f |
   sed \"s:^:$(basename $f) :\"; done |
   perl -lne '
      print \"$1 $3$2 $4\" if m/(sub-.*)_(acq-dwi|dwi|acq-func).*?(run-\\d+|\\.).*?json \"(.*)\"/
   '"
out <- system(intern=T, cmd)
# [1] "sub-10195_ses-20160317 run-1 11:36:30.930000"
# [2] "sub-10195_ses-20170824 . 16:39:30.100000"    
# [3] "sub-10195_ses-20170824 run-1 16:27:12.852500"

d <-
   read.table(text=out, col.names=c('id','run','acqtime')) %>%
   mutate(acqtime=acqtime %>% hms %>% as.numeric) %>%
   group_by(id, run) %>% mutate(r=rank(acqtime, ties.method="first")) %>%
  # transpose to wide so we have a dwi time column. row per visit
  # remove anyone without a dwi time
  filter(r==1) %>% select(-r) %>%
   # transpose to wide so we have a dwi time column. row per visit
   # remove anyone without a dwi time
   spread(run,acqtime) %>%
   rename(dwi='.dwi') %>%
   filter(!is.na(dwi)) %>%
   # put back into long format so we can find best column
   gather(run,acqtime,-id,-dwi) %>%
   filter(!is.na(acqtime)) %>% 
   # pick the fmap run row with the min diff between dwi and fmap acquisition time
   group_by(id) %>% 
   mutate(acqdiff=abs(dwi-acqtime), n_ses_fmap=n()) %>%
   filter(min(acqdiff)==acqdiff)

#   id                        dwi run   acqtime acqdiff n_ses_fmap
#   <fct>                   <dbl> <chr>   <dbl>   <dbl>      <int>
# 1 sub-10195_ses-20170824 59970. run-1  59233.    737.          1
# 2 sub-10195_ses-20190321 41592. run-1  40627.    965.          1

write.table(d, file="txt/best_fmap_for_dwi.txt", row.names=F, quote=F, sep="\t")
