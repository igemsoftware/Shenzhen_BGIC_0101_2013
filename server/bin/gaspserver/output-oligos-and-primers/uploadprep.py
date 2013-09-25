import os, glob
from Bio import SeqIO

sequences = []

for infile in glob.glob('*.fasta'):
    handle = open(infile)
    for seqrec in SeqIO.parse(handle, "fasta"):
        sequences.append(seqrec)
    handle.close()

fileout = open("agilent-upload.txt","w")

for seqrec in sequences:
    line = seqrec.id + '\t' + str(seqrec.seq) + '\n'
    fileout.write(line)

fileout.close()

