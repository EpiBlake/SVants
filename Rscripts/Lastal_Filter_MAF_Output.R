###Script Info
##Version: 0.1
##Author: Blake Hanson 

###~~~~~Arguments~~~~~
args<-commandArgs(TRUE)

###~~~~~Libraries~~~~~


###~~~~~Functions~~~~~


###~~~~~Variables~~~~~
MAFFilterOutput <- args[1]
SeqLength <- as.numeric(args[2])
GeneticElementMatch <- as.numeric(args[3])
SeqQuality <- as.numeric(args[4])
OverlapLen <- as.numeric(args[5])

###~~~~~Code to be run~~~~~~
#Read in csv file
MAF_DF <- read.csv(MAFFilterOutput, header=TRUE, sep=",", stringsAsFactors = FALSE)

#Subset DF to only include reads longer than X bases
MAF_DF_L <- MAF_DF[ which(MAF_DF$length > SeqLength),]

#Subset on Match to genetic element
MAF_DF_LM <- MAF_DF_L[ which(MAF_DF_L$identity_length > GeneticElementMatch),]

#Subset on the % identity of the match to the genetic element
MAF_DF_LMP <- MAF_DF_LM[ which(MAF_DF_LM$identity_percent > (SeqQuality-3)),]

#Subset to only include reads that have an overhang greater than X bases
MAF_DF_LMPO <- MAF_DF_LMP[ which(MAF_DF_LMP$query_start > OverlapLen | (MAF_DF_LMP$length - MAF_DF_LMP$query_stop) > OverlapLen),]

#Write out subsetted DF to new csv after stripping the names from previous csv name
OutFile <- paste(substr(MAFFilterOutput, 1, nchar(MAFFilterOutput)-4), "_subset.csv", sep="")
write.csv(MAF_DF_LMPO, OutFile, row.names = FALSE)

