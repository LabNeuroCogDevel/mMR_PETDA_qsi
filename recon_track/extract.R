library(dplyr)
library(stringr)
library(tidyr)
allsubjs <- Sys.glob('1*2*_*.nii.stat.txt')
readsubjs <- function(f) read.table(f,sep="\t") %>% mutate(visit=str_extract(f,'\\d+_\\d+'))
d <- lapply(allsubjs, readsubjs) %>% bind_rows()
names(d) <- c('var','val','visit')# then to get just one variable
d <- d %>% separate(visit,c('visit','tract')) %>% mutate(id=substr(visit,0,5))
write.csv(d,'all.stat.csv',row.names=F, quote=F)

d <- read.csv('all.stat.csv')
d %>% filter(grepl('nrdi12L sd',var))
