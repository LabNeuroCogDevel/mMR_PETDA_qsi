library(dplyr)
library(stringr)
allsubjs <- Sys.glob('1*2*_*.nii.stat.txt')
readsubjs <- function(f) read.table(f,sep="\t") %>% mutate(visit=str_extract(f,'\\d+_\\d+'))
d <- lapply(allsubjs, readsubjs) %>% bind_rows()
names(d) <- c('var','val','visit')# then to get just one variable
write.csv(d,'all.stat.txt',row.names=F, quote=F)

d <- read.csv('all.stat.txt')
d %>% filter(grepl('nrdi12L sd',var))
