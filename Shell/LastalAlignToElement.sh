#!/usr/bin/env bash

################################################################################

Usage="
This script takes MinION reads and algins them to a defined genetic element using last
Usage: $(basename $0) CONFIG_FILE_NAME

CONFIG_FILE_NAME should contain the following parameters

FASTAFILE=
OUTPUTLOCATION=
ELEMENTREFERENCELOCATION=
GENOMEREFERENCELOCATION=
SUBSETSEQLENGTH=
GENETICELEMENTMATCH=
SEQQUALITY=
OVERLAPLEN=
"

CONFIGFILE=${1?"$USAGE"}
source $CONFIGFILE
FASTANAME=$(echo "$FASTAFILE" | rev | cut -d/ -f1 | rev)
FILTEREDFASTAFILE=${OUTPUTLOCATION}/${FASTANAME%.fasta}_filtered.fasta
MASKEDFASTAFILE=${OUTPUTLOCATION}/${FASTANAME%.fasta}_MaskedForElement.fasta
ALIGNOUTPUTFILENAME=${OUTPUTLOCATION}/${FASTANAME%.fasta}_AlignedToElement.maf
MAFFILTEROUTPUT=${OUTPUTLOCATION}/${FASTANAME%.fasta}_AlignedToElement_filter.csv
BEDFILE=${MAFFILTEROUTPUT%.csv}_alignmentpositions.bed
FILTEREDALIGNOUTPUTFILENAME=${OUTPUTLOCATION}/${FASTANAME%.fasta}_Filtered_AlignedToGenome.maf
FINALMAPPINGLOCATION=${FILTEREDALIGNOUTPUTFILENAME%.maf}_finalmapping.csv
FILTERMAFLOCATION="/Users/bhanson/Documents/Data/Scripts/Scripts/Pipelines/Lastal_MinION_GeneticElement/Python/filter_maf.py"
SUBSETMAFLOCATION="/Users/bhanson/Documents/Data/Scripts/Scripts/Pipelines/Lastal_MinION_GeneticElement/Rscripts/Lastal_Filter_MAF_Output.R"

################################################################################

#Check output directory, if doesnt exist, makedir
if [[ ! -d $OUTPUTLOCATION ]]; then
    mkdir -p $OUTPUTLOCATION
fi

#This performs the intial alignment to the reference element
#Parameters: T 0 - local alignment; Q 0 - ignore quality information (no preset for ONT);
# a 1 - gap existance cost; s 2 - use both forward and reverse strands; f1 - use MAF format;
# j7 - adds expected count inforamation  
echo "Performing Lastal Alignment on: " $FASTAFILE
lastal -T 0 -Q 0 -a 1 -s 2 -f1 -j7 $ELEMENTREFERENCELOCATION $FASTAFILE > $ALIGNOUTPUTFILENAME

#Edit maf file to remove junk from header and put on appropriate header name
echo "Modifying maf file and apply filtering criteria"
tail -n +19 < $ALIGNOUTPUTFILENAME > ${ALIGNOUTPUTFILENAME%.maf}_withheader.temp
{ echo "##maf"; cat ${ALIGNOUTPUTFILENAME%.maf}_withheader.temp; } > ${ALIGNOUTPUTFILENAME}_withheader.maf
rm ${ALIGNOUTPUTFILENAME%.maf}_withheader.temp

#Calls the filter_maf.py script that outputs the alignment stats for filtering and processing
echo "running Python script"
python $FILTERMAFLOCATION -i ${ALIGNOUTPUTFILENAME}_withheader.maf -o $MAFFILTEROUTPUT

#Subset the alignment stats on pre-determined cutoffs
echo "running R script"
Rscript $SUBSETMAFLOCATION $MAFFILTEROUTPUT $SUBSETSEQLENGTH $GENETICELEMENTMATCH $SEQQUALITY $OVERLAPLEN

#Subset fasta file to only include the reads covering the element of interest
echo "subsetting quality mapped reads from fasta file"
cut -d "," -f1 ${MAFFILTEROUTPUT%.csv}_subset.csv > ${MAFFILTEROUTPUT%.csv}.tmp
tr -d '"' < ${MAFFILTEROUTPUT%.csv}.tmp > ${MAFFILTEROUTPUT%.csv}.tmp2
for i in $(cat  ${MAFFILTEROUTPUT%.csv}.tmp2); do grep -A 1 $i $FASTAFILE; done > ${FILTEREDFASTAFILE}.tmp
cut -d " " -f1 ${FILTEREDFASTAFILE}.tmp > $FILTEREDFASTAFILE
rm ${MAFFILTEROUTPUT%.csv}.tmp ${MAFFILTEROUTPUT%.csv}.tmp2 ${FILTEREDFASTAFILE}.tmp

#Subset the output from filter_maf.py to only include the read name and the alignment coordinates
cut -d "," -f1,6,7 ${MAFFILTEROUTPUT%.csv}_subset.csv > ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp
tr -d '"' < ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp > ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp2
tail -n +2 < ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp2 > ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp3
tr "," "\t" < ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp3 > ${MAFFILTEROUTPUT%.csv}_alignmentpositions.bed
rm ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp2 ${MAFFILTEROUTPUT%.csv}_alignmentpositions.tmp3

#Soft mask the reads using the alignment locations from the filter_maf.py script
echo "Soft-masking reads"
bedtools maskfasta -fi $FILTEREDFASTAFILE -bed $BEDFILE -fo $MASKEDFASTAFILE -soft

#Align the soft-masked reads to original reference
echo "Aligning soft-masked reads to reference genome"
lastal -T 0 -Q 0 -a 1 -s 2 -u 3 -f1 -j7 $GENOMEREFERENCELOCATION $MASKEDFASTAFILE > $FILTEREDALIGNOUTPUTFILENAME

#Edit maf file to remove junk from header and put on appropriate header name
echo "Determining alignment coordintates"
tail -n +19 < $FILTEREDALIGNOUTPUTFILENAME > ${FILTEREDALIGNOUTPUTFILENAME%.maf}_withheader.temp
{ echo "##maf"; cat ${FILTEREDALIGNOUTPUTFILENAME%.maf}_withheader.temp; } > ${FILTEREDALIGNOUTPUTFILENAME%.maf}_withheader.maf
rm ${FILTEREDALIGNOUTPUTFILENAME%.maf}_withheader.temp

#Determine mapping positions of the soft-masked reads to find where they insert into the reference 
python $FILTERMAFLOCATION -i ${FILTEREDALIGNOUTPUTFILENAME%.maf}_withheader.maf -o $FINALMAPPINGLOCATION

#Compare mapping positions to reference genome annotation to get gene names and locations of insertion (look at intergenic vs intragenic, look at orientation of insertion that may result in over-expression)

