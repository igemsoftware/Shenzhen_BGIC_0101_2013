import os
from Bio import Entrez,SeqIO,Seq,Alphabet
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
from Bio.Alphabet import IUPAC

from Primerselectiontools import *

def printPrimerSequences(primers):
    for primer in primers:
        for prim in primer:
            print str(prim)
        print "--------------------"

def printNumOfPrimers(primers):
    numoftotprimers = 0
    for primer in primers:
        numoftotprimers += len(primer)
    print "Total 25mers (unique): " + str(len(primers)) + " (" + str(numoftotprimers) + ")"

def parsePrimerFile(filename):
    #enter all possible 25mers in a 2d array
    records = SeqIO.parse(open(filename), "fasta")
    primers = []
    for record in records:
        recseq = record.seq
        possibleprimers = []
        for i in range(5):
            tempseq = recseq[i:20+i]
            possibleprimers.append(tempseq)
        primers.append(possibleprimers)
    return primers

def restrictionEnzymeFilter(filename, primers):
    records = SeqIO.parse(open(filename), "fasta")
    seqtoremovelist = []
    for record in records:
        seqtoremovelist.append(record.seq)
        
    newprimers = []
    for primer in primers:
        newprimer = []
        for prim in primer:
            keep = 1
            for seqtoremove in seqtoremovelist:
                if not prim.find(seqtoremove)==-1:
                    keep = -1
            if keep==1:
                newprimer.append(prim)        
                
        if len(newprimer)>0:
            newprimers.append(newprimer)
    
    return newprimers

def temperatureFilter(primers, lowtemp, hightemp):
    newprimers = []
    for primer in primers:
        newprimer = []
        for prim in primer:
            Tm = oligoTm(prim)
            if Tm > lowtemp and Tm < hightemp:
                newprimer.append(prim)
        if len(newprimer)>0:
            newprimers.append(newprimer)
    
    return newprimers

def selfDimers(primers, cutoff):
    newprimers=[]
    for primer in primers:
        newprimer = []
        for prim in primer:
            score = primerdimers(prim,prim)
            if not score>cutoff:
                newprimer.append(prim)
        if len(newprimer)>0:
            newprimers.append(newprimer)
    return newprimers

def secStructure(primers, cutoff):
    newprimers=[]
    for primer in primers:
        newprimer = []
        for prim in primer:
            score = calcSecondaryStructure(prim)
            if score>cutoff:
                newprimer.append(prim)
        if len(newprimer)>0:
            newprimers.append(newprimer)
    return newprimers



filename = "bc25mer.240k.fasta"
#enter all possible 25mers in a 2d array
# the above file is from Elledge's paper "Design of 240,000 orthogonal 25mer DNA barcode probes": http://www.pnas.org/content/106/7/2289.full
# see http://elledgelab.bwh.harvard.edu/Barcode/
primers = parsePrimerFile(filename)
#self-check
#printPrimerSequences(primers)
print "Initial Setup" 
printNumOfPrimers(primers)

filename = "restenz.txt"
primers = restrictionEnzymeFilter(filename, primers)

#self-check
#printPrimerSequences(primers)
print "Restriction Enzyme Filter"
printNumOfPrimers(primers)

lowtemp = 62
hightemp = 64
primers = temperatureFilter(primers, lowtemp, hightemp)
print "Melting Temp Filter"
printNumOfPrimers(primers)

selfdimercutoff = 3
primers = selfDimers(primers,selfdimercutoff)
print "Self Dimerization Cutoff"
printNumOfPrimers(primers)

#secstructcutoff = -2
#primers = secStructure(primers,secstructcutoff)
#print "Secondary Structure Cutoff"
#printNumOfPrimers(primers)

#Output Primers
filename = "filteredprimers1.fasta"
fileout = open(filename,'w')
for i in range(len(primers)):
    fileout.write(">sk20mer-"+str(i+1)+"\n")
    fileout.write(str(primers[i][0])+"\n")

fileout.close()
