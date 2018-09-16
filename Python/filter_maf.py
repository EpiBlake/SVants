'''                                                                                                                                 
filter_maf.py
=============
                                                                                                                                    
:Authors: Jethro Johnson & Blake Hanson

Use
---
cat <INPUT> | python filter_maf.py > <OUTPUT>

or: 

python filter_maf.py --input <INPUT> --output <OUTPUT>



Commandline Options
-------------------
'''

import os,sys
import argparse
import bx.align.maf

                                          
def main(args=sys.argv):

    parser = argparse.ArgumentParser(globals()["__doc__"])
    
    parser.add_argument("-i", "--input", dest="input",
                        help="Name of input file")
    parser.add_argument("-o", "--output", dest="output",
                        help="Name of ouptut file")

    args = parser.parse_args()
    parser.set_defaults(input=sys.stdin,
                        output=sys.stdout
                        )

    # output name, length, identity_match, identity_length,
    # identity_percent, query_start, query_stop, direction
    if args.output:
        outf = open(args.output, 'w')
    else:
        outf = sys.stdout

    outf.write("name,length,identity_match,identity_length,identity_percent"
               ",query_start,query_stop,direction,contig,reference_start,reference_stop,e_value\n")
        


    def fetch_block_stats(block):
        '''return required maf attributes'''
        # calculate errors and total alignment length
        errors = 0
        total = 0
        for base in block.column_iter():
            if base[0] != base[1]:
                errors += 1
            total += 1

        identity_match = total - errors
        identity_percent = 100.0*(identity_match/float(total))
        identity_length = total
        e_value = float(block.attributes["fullScore"])
        
        # fetch query attributes
        query = block.components[1]
        name = query.src
        length = query._src_size
        query_start = query.forward_strand_start
        query_stop = query.forward_strand_end
        direction = query.strand
        ref = block.components[0]
        contig = ref.src
        ref_start = ref.forward_strand_start
        ref_stop = ref.forward_strand_end

        # write alignment attributes
        attr = [name, length, identity_match, identity_length,
                round(identity_percent, 2), query_start, query_stop, 
                direction, contig, ref_start, ref_stop, e_value]
 
        return attr


    # read in MAF file
    if args.input:
        inf = open(args.input)
    else:
        inf = sys.stdin

    maf = bx.align.maf.Reader(inf)
    # fetch first alignment block in maf file
    bl = maf.next()
    bl_attr = fetch_block_stats(bl)

    # iterate over remainder of MAF file
    for block in maf:
        attr = fetch_block_stats(block)
        if attr[0] != bl_attr[0]:
            outf.write(','.join(map(str, bl_attr)) + '\n')
            bl_attr = attr
        elif attr[-1] > bl_attr[-1]:
            bl_attr = attr
        else:
            continue

if __name__ == "__main__":
    sys.exit(main(sys.argv))
