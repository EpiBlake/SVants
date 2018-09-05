#This script takes the maf file output from lastal (with the -j7 parameter) and outputs the alignment stats
#Usage: LastalProbabilities.sh [INCOMINGFILENAME]

INCOMINGFILENAME=$1
OUTPUTFILENAME=${1%.maf}.txt

echo "Starting File:" $INCOMINGFILENAME

HEADERNAMES="Ccolumn Correct_A AasC AasG AasT CasA Correct_C CasG CasT GasA GasC Correct_G GasT TasA TasC TasG Correct_T CountOfMatchesAndMismatches CountDeletions CountInsertions CountDeleteOpens CountInsertOpens CountPairsIndel UnalignedLetterPairs UnalignedLetterPairOpens AdjacentPairsofDelitions AdjacentPairsofInsertions"

echo $HEADERNAMES > $OUTPUTFILENAME
grep "^c " $INCOMINGFILENAME >> $OUTPUTFILENAME

echo "Writing File:" ${OUTPUTFILENAME%txt}csv
tr " " "," < $OUTPUTFILENAME > ${OUTPUTFILENAME%txt}csv
rm $OUTPUTFILENAME