#!/usr/bin/env bash

################################################################################
USAGE="
This script takes MinION reads and algins them to a defined reference genome using last
Usage: $0 FastaFileName ReferenceFileLocation OutputDirectory ConfigFile
"
################################################################################

#Process cmdline args
if [[ $# -ne 4 ]]; then
    echo "$USAGE"
else
    INCOMINGFILENAME=$1
    REFERENCELOCATION=$2
    OUTPUTLOCATION=$3
    CONFIGFILE=$4
fi

#if [[ ! -d $OUTPUTLOCATION ]]; then
    #mkdir -p "$OUTPUTLOCATION"
#fi

################################################################################

source $CONFIGFILE
FILENAME=${INCOMINGFILENAME%.fasta}
ALIGNOUTPUTFILENAME=${OUTPUTLOCATION}/$(basename "$FILENAME")_AlignedToReference.maf
PROBOUTPUTFILENAME=${OUTPUTLOCATION}/$(basename "$FILENAME")_AlignedToReference_probs.maf

#This performs the intial alignment to the reference genome
#Parameters: T 0 - local alignment; Q 0 - ignore quality information (no preset for ONT);
# a 1 - gap existance cost; s 2 - use both forward and reverse strands; f1 - use MAF format;
# j7 - adds expected count inforamation  
echo "Performing Lastal Alignment on: " $INCOMINGFILENAME
lastal -P $CORES -T 0 -Q 0 -a 1 -s 2 -f1 -j7 $REFERENCELOCATION $INCOMINGFILENAME > $ALIGNOUTPUTFILENAME


#Computes the probabilities that the alignment representes the genomic source of the read. 
#Discards alignments with mismap probability >0.01
echo "Calculating alignment probabilities and filtering low quality alignments"
last-map-probs $ALIGNOUTPUTFILENAME > $PROBOUTPUTFILENAME

#Calls the LastalProbabilities.sh script to pull probabilities out
echo "Writing alignment probability information to: " $PROBOUTPUTFILENAME
$LASTALPROBABILITIES $PROBOUTPUTFILENAME

#Calculate Alginment Stats and Details
echo "Generating Alignment Stats and Details"
Rscript $RCALLLASTALRSCRIPT $LASTALRSCRIPT_ALIGNMENTSTATS $INCOMINGFILENAME $REFERENCELOCATION ${PROBOUTPUTFILENAME%.maf}.csv $OUTPUTLOCATION
