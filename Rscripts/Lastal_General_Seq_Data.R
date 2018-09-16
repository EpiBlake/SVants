###Script Info
##Version: 0.1
##Author: Blake Hanson

###~~~~~Arguments~~~~~
args<-commandArgs(TRUE)

###~~~~~Libraries~~~~~
suppressMessages(library(Biostrings))

###~~~~~Functions~~~~~


###~~~~~Variables~~~~~
FastaFile <- args[1]


###~~~~~Code to be run~~~~~~
A <- readDNAStringSet(FastaFile)
print(paste("Number of reads:", nrow(as.data.frame(width(A)))))
print(paste("Number of bases:", sum(width(A))))
print(paste("Minimum sequence length:", min(width(A))))
print(paste("Maximum sequence length:", max(width(A))))
print(paste("Mean Sequence Length:", mean(as.numeric(width(A)))))
