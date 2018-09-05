###Script Info
##Version: 0.1
##Author: Blake Hanson 
##Usage: Rscript Call_MinIONQC_Report.R [LOCATION_Rmd_SCRIPT] [FASTAFILENAME] [REFERENCELOCATION] [PROBABILITYMAF] [OUTPUTLOCATION]

###~~~~~Arguments
args<-commandArgs(TRUE)

###~~~~~Libraries
library(rmarkdown)

###~~~~~Functions

###~~~~~Variable Definitions - for Debugging
#ReportScript <- "~/Documents/Data/Scripts/Pipelines/Lastal_MinION_GeneticElement/Rscripts/Lastal_AlignmentStat.Rmd"
#RunNameVar="UCLA_KPC_4hrReload_pass_2D.fasta"
#GenomeNameVar="HKPC_PBcR"
#ProbTableLoc="~/Documents/Data/StudyData/WGS/MinION/HKPC/processed/UCLA_KPC_4hrReload_pass_2D_AlignedToReference_probs.csv"

###~~~~~Code to Run
RunName <- basename(args[2])
RunNameSub <- substr(RunName, 1, (nchar(RunName)-6))
OutputFileName <- paste(args[5], "/", RunNameSub, "_AlignmentStats.pdf", sep="")

render(args[1], params = list(RunNameVar=args[2], GenomeNameVar=args[3], ProbTableLoc=args[4]), output_file=OutputFileName)



