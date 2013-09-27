import json
import sys
from Bio import SeqIO
import os, glob, time
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
from Bio.Alphabet import IUPAC
from Bio.Alphabet import generic_dna
from Bio import Alphabet
from Bio import Restriction
from Bio.Restriction import *

from Primerselectiontools import *

import smtplib
from email.mime.text import MIMEText

#configFile = "plate-based-assembly-from-ols-pool-config.json"
configFile = sys.argv[1]  
configString = "".join([line for line in open(configFile).readlines()])
config = json.loads(configString)
emailAddressFrom = "adam.h.marblestone@gmail.com"
emailAddressTo =  "adam.h.marblestone@gmail.com"
sendEmails = False
outputpath = 'output-oligos-and-primers/'
# pretty print the config file contents
# s = json.dumps(configDict, sort_keys=True, indent=4)
# print s

def sendEmail(address, textfile, attachmentfiles = []):
    '''This method only works on Unix/MaxOSX'''
    print "sending email"
    msg = open(textfile).read()
    sendmail_location = "/usr/sbin/sendmail" # sendmail location
    if len(attachmentfiles) > 0:
        # include the attachments
        p = os.popen("%s %s" % (sendmail_location, address), "w")
        for i in range(len(attachmentfiles)):
            attachmentfile = attachmentfiles[i]
            msg += "\n" + open(attachmentfile).read() + "\n"
        p.write("From: %s\n" % emailAddressFrom)
        p.write("Subject: GASP job output files\n")
        p.write("\n") # blank line separating headers from body
        p.write("\n")
        p.write(msg)
        status = p.close()
        if status != 0:
               print "Sendmail exit status", status, "\n"
    else:
        p = os.popen("%s -t" % sendmail_location, "w")
        p.write("From: %s\n" % emailAddressFrom)
        p.write("To: %s\n" % address)
        p.write("Subject: GASP job\n")    
        p.write("\n") # blank line separating headers from body
        p.write(msg)
        status = p.close()
        if status != 0:
               print "Sendmail exit status", status, "\n"

# takes a path, grabs all .fasta files from the directory and returns a list of SeqRecords for those sequences
# build sequences should be exactly what you want to build including restriction sites, etc.
def obtainBuildSequences(infile):
    sequences = []
    handle = open(infile)
    for seqrec in SeqIO.parse(handle, "fasta"):
        sequences.append(seqrec)
    handle.close()
    return sequences

# takes a path, grabs all forward and reverse primers, and returns a vector with the primer sequences.
# does not check sequence similarity
def obtainAmpPrimerSequences(forward, reverse):
    forwardprim = []
    handle = open(forward)
    for seqrec in SeqIO.parse(handle,"fasta"):
        forwardprim.append(seqrec)
    handle.close()
    
    reverseprim = []
    handle = open(reverse)
    for seqrec in SeqIO.parse(handle,"fasta"):
        reverseprim.append(seqrec)
    handle.close()
    
    prim = [forwardprim, reverseprim]
    return prim

def run_gasp(configDict):

    infile = configDict["buildSequencesFile"]
    skippednames = configDict["skip"]
    try:
        sequences = obtainBuildSequences(infile)
        ampprimers = obtainAmpPrimerSequences(configDict["forwardPrimersLibraryFile"], configDict["reversePrimersLibraryFile"])
    except:
        print "Unable to process file %s" % infile
        return
    
    print "processing %s\n" % infile
    
    reportFile = outputpath + "".join(s for s in configDict["buildSequencesFile"].split("/")[-1].split(".")[:-1]) + "-REPORT.txt"
    reportFileHandle = open(reportFile, 'w')
    reportFileHandle.write("Report for input file %s\n" % infile)
    if configDict["fixedPrimerSetThroughoutFile"] == "False":
        reportFileHandle.write("The build sequences in this file are divided onto plates and plate wells, each receiving their own primer sets.\n")
    elif configDict["fixedPrimerSetThroughoutFile"] == "True":
        fixedIndex = configDict["fixedIndex"]
        fixedPlateNumber = configDict["fixedPlateNumber"]
        if len(sequences) > 1:
            reportFileHandle.write("\tThe build sequences in this file all receive the same primer sets.\n")
            reportFileHandle.write("\tThe primer sets correspond to plate index %s and position index %s in the standard plate-based amplification scheme.\n" % (fixedPlateNumber, fixedIndex))
        else:
            reportFileHandle.write("\tThere is only one build sequence in this file.\n")
            reportFileHandle.write("\tIt receives primers sets corresponding to plate index %s and position index %s in the standard plate-based amplification scheme.\n" % (fixedPlateNumber, fixedIndex))
    
    oligostosynthrecs = []
    bbprimersf = []
    bbprimersr = []
    positionprimersf = []
    positionprimersr = []
    plateprimersf = []
    plateprimersr = []
    
    index = 0
    totalindex = 0
    platenumber = configDict["initialPlateNum"]

    for buildseq in sequences:
        
        if buildseq.id in skippednames:
            print "Skipped %s" % buildseq.id
            reportFileHandle.write("\t\n\nSkipped build sequence %s\n" % buildseq.id)
            continue
        else:
            reportFileHandle.write("\t\n\nProcessed sequence %s\n" % buildseq.id)
            
        
        # add building block primers
        if configDict["fixedPrimerSetThroughoutFile"] == "False":
            updatedbuildseq = bufferBuildSequences(buildseq, ampprimers[0][index+100], ampprimers[1][index+100])
        elif configDict["fixedPrimerSetThroughoutFile"] == "True":
            fixedIndex = configDict["fixedIndex"]
            updatedbuildseq = bufferBuildSequences(buildseq, ampprimers[0][fixedIndex+100], ampprimers[1][fixedIndex+100] )
            
        # find plate specific primer
        if configDict["fixedPrimerSetThroughoutFile"] == "False":    
            plateforprimer = ampprimers[0][platenumber-2]
            platerevprimer = ampprimers[1][platenumber-2]
        elif configDict["fixedPrimerSetThroughoutFile"] == "True":
            fixedIndex = configDict["fixedIndex"]
            fixedPlateNumber = configDict["fixedPlateNumber"]
            plateforprimer = ampprimers[0][fixedPlateNumber-2]
            platerevprimer = ampprimers[1][fixedPlateNumber-2]
            
        oligos = []
    
        REVector = configDict["REVector"]
        RESpacing = configDict["RESpacing"]
        REtouse = None
    
        # if we've chosen to explicitly specify the single RE that we want to use
        if configDict["SearchForRE"] == "False" and configDict["REToUse"] != None:
            REVector = [str(configDict["REToUse"])]
            RESpacing = [int(RESpacing[configDict["REVector"].index(configDict["REToUse"])])]
    
        # loop through the set of RE's that we are considering
        for restenzindex in range(len(REVector)):
            restenz = get_class("Bio.Restriction.Restriction.%s" % REVector[restenzindex])
            if not restenz.search(updatedbuildseq):
                REtouse = restenz
                REspacingtouse = RESpacing[restenzindex]
                break
        if REtouse == None:
            print restenz.search(updatedbuildseq)
            print updatedbuildseq
            print "Error: No restriction enzyme found for building block " + buildseq.id
            index += 1
            if index % 96 == 0:
                index = 0
                platenumber += 1
                plateforprimer = ampprimers[0][platenumber-2]
                platerevprimer = ampprimers[1][platenumber-2]
            totalindex += 1
            continue
        
        # split oligos
        oligosizemax = (configDict["oligoSizeMax"] - 80) - configDict["insertionSizeToKillRESite"] - len(REtouse.site)*2 - REspacingtouse*2
        try:
            oligos = optimizedSplit(updatedbuildseq, oligosizemax, configDict["lengthleeway"], configDict["positionleeway"], configDict["avgoverlapsize"], configDict["overlaptemps"], configDict["deltaGThresholdForOverlaps"], configDict["selfDimersThreshold"], configDict["seqsToAvoidInOverlapRegions"])
        except:
            print "\nError: Not able to find an overlap structure consistent with the parameters in the config file.\nTry increasing selfDimersThreshold and re-running the script.\n"
            index += 1
            if index % 96 == 0:
                index = 0
                platenumber += 1
                plateforprimer = ampprimers[0][platenumber-2]
                platerevprimer = ampprimers[1][platenumber-2]
            totalindex += 1
            continue
            
        # buffer oligos with plate specific and position specific primers
        if configDict["fixedPrimerSetThroughoutFile"] == "False":
            newoligos = bufferOligoSequences(updatedbuildseq, oligos, REtouse, REspacingtouse, ampprimers[0][index+platenumber*100], ampprimers[1][index+platenumber*100], plateforprimer, platerevprimer)
        elif configDict["fixedPrimerSetThroughoutFile"] == "True":
            fixedIndex = configDict["fixedIndex"]
            fixedPlateNumber = configDict["fixedPlateNumber"]
            newoligos = bufferOligoSequences(updatedbuildseq, oligos, REtouse, REspacingtouse, ampprimers[0][fixedIndex+fixedPlateNumber*100], ampprimers[1][fixedIndex+fixedPlateNumber*100], plateforprimer, platerevprimer)
            
        #check number of restriction sites
        problemWithRESites = False
        for i in newoligos:
            # print str(i) + '\t' + str(len(i))
            if not len(REtouse.search(i)) == 2:
                problemWithRESites = True

        oligonamebase = buildseq.id + '-' + str(REtouse)
        if not problemWithRESites:
            reportFileHandle.write('\nSuccess: Correctly designed oligos for %s \n' % oligonamebase)
            print 'Success: Correctly designed oligos for ' + oligonamebase
        else:
            print '\nError: Incorrect number of restriction sites per oligo in %s: a RE site may have been created at the junction between two concatenated primers\n' % oligonamebase
            reportFileHandle.write('\nError: Incorrect number of restriction sites per oligo in %s\n' % oligonamebase)
            
        for i in range(len(newoligos)):
            newid = oligonamebase + '-' + str(i)
            oligostosynthrecs.append(SeqRecord(newoligos[i], id=newid))

        # we only change primers here if we are automatically populating a plate
        # otherwise, if we have FIXED pos primers, we leave the primers fixed according to values in the config file
        if configDict["fixedPrimerSetThroughoutFile"] == "False":
            bblinef = ampprimers[0][index+100].id + '\t' + str(ampprimers[0][index+100].seq) + '\t' + oligonamebase + '\n'
            bbliner = ampprimers[1][index+100].id + '\t' + str(ampprimers[1][index+100].seq) + '\t' + oligonamebase + '\n'
            posprimf = ampprimers[0][index+platenumber*100].id + '\t' + str(ampprimers[0][index+platenumber*100].seq) + '\t' + oligonamebase + '\n'
            posprimr = ampprimers[1][index+platenumber*100].id + '\t' + str(ampprimers[1][index+platenumber*100].seq) + '\t' + oligonamebase + '\n'
            platef = plateforprimer.id + '\t' + str(plateforprimer.seq) + '\t' + oligonamebase + '\n'
            plater = platerevprimer.id + '\t' + str(platerevprimer.seq) + '\t' + oligonamebase + '\n'
            reportFileHandle.write("\t\tFirst amplify this sequence using 'plate specific' primers %s and %s\n" % (plateforprimer.id, platerevprimer.id))
            reportFileHandle.write("\t\tNext amplify this sequence using 'position specific' primers %s and %s\n" % (posprimf.split('\t')[0], posprimr.split('\t')[0]))
            reportFileHandle.write("\t\tFinally amplify this sequence using building block primers %s and % s\n" % (ampprimers[0][index+100].id, ampprimers[1][index+100].id))
            if ampprimers[0][index+platenumber*100] == ampprimers[0][index+100] or ampprimers[1][index+platenumber*100] == ampprimers[1][index+100]:
                print ">>WARNING: The building block primers are the same as the position specific primers here. Make sure plate #1 is left unused in the configuration file!!!"
                reportFileHandle.write(">>WARNING: The building block primers are the same as the position specific primers here. Make sure plate #1 is left unused in the configuration file!!!\n")
                sys.exit()
                
        elif configDict["fixedPrimerSetThroughoutFile"] == "True":
            fixedIndex = configDict["fixedIndex"]
            fixedPlateNumber = configDict["fixedPlateNumber"]
            bblinef = ampprimers[0][fixedIndex+100].id + '\t' + str(ampprimers[0][fixedIndex+100].seq) + '\t' + oligonamebase + '\n'
            bbliner = ampprimers[1][fixedIndex+100].id + '\t' + str(ampprimers[1][fixedIndex+100].seq) + '\t' + oligonamebase + '\n'
            posprimf = ampprimers[0][fixedIndex+fixedPlateNumber*100].id + '\t' + str(ampprimers[0][fixedIndex+fixedPlateNumber*100].seq) + '\t' + oligonamebase + '\n'
            posprimr = ampprimers[1][fixedIndex+fixedPlateNumber*100].id + '\t' + str(ampprimers[1][fixedIndex+fixedPlateNumber*100].seq) + '\t' + oligonamebase + '\n'
            platef = plateforprimer.id + '\t' + str(plateforprimer.seq) + '\t' + oligonamebase + '\n'
            plater = platerevprimer.id + '\t' + str(platerevprimer.seq) + '\t' + oligonamebase + '\n'
            
            if ampprimers[0][fixedIndex+fixedPlateNumber*100] == ampprimers[0][fixedIndex+100] or ampprimers[1][fixedIndex+fixedPlateNumber*100] == ampprimers[1][fixedIndex+100]:
                print ">>WARNING: The building block primers are the same as the position specific primers here. Make sure plate #1 is left unused in the configuration file!!!"
                reportFileHandle.write(">>WARNING: The building block primers are the same as the position specific primers here. Make sure plate #1 is left unused in the configuration file!!!\n")
                exit()
                
            if index == 0:
                reportFileHandle.write("\t\tFirst amplify this sequence using 'plate specific' primers %s and %s\n" % (plateforprimer.id, platerevprimer.id))
                reportFileHandle.write("\t\tNext amplify this sequence using 'position specific' primers %s and %s\n" % (posprimf.split('\t')[0], posprimr.split('\t')[0]))
                reportFileHandle.write("\t\tFinally amplify this sequence using building block primers %s and % s\n" % (ampprimers[0][fixedIndex+100].id, ampprimers[1][fixedIndex+100].id))
            else:
                reportFileHandle.write("\t\tDitto for this sequence...\n")
        
        bbprimersf.append(bblinef)
        bbprimersr.append(bbliner)
        positionprimersf.append(posprimf)
        positionprimersr.append(posprimr)
        plateprimersf.append(platef)
        plateprimersr.append(plater)

        index += 1
        if index % 96 == 0:
            index = 0
            platenumber += 1
            plateforprimer = ampprimers[0][platenumber-2]
            platerevprimer = ampprimers[1][platenumber-2]
        totalindex += 1

    # output oligos to synthesize
    oligoOutFile = outputpath + "".join(s for s in configDict["buildSequencesFile"].split("/")[-1].split(".")[:-1]) + "-oligo-output.fasta"
    handle = open(oligoOutFile, "w")
    SeqIO.write(oligostosynthrecs, handle, "fasta")
    handle.close()

    # output primers for PCR
    primerOutFile = outputpath + "".join(s for s in configDict["buildSequencesFile"].split("/")[-1].split(".")[:-1]) + "-primer-output.txt"
    handle = open(primerOutFile,"w")
    handle.writelines(bbprimersf)
    handle.writelines(bbprimersr)
    handle.writelines(positionprimersf)
    handle.writelines(positionprimersr)
    handle.writelines(plateprimersf)
    handle.writelines(plateprimersr)
    handle.close()

    print "\noutputs written to: \n\n%s\n%s\n" % (oligoOutFile, primerOutFile)
    
def obtainSynthDict(infile):
    sequences = []
    handle = open(infile)
    for seqrec in SeqIO.parse(handle, "fasta"):
        sequences.append(seqrec)
    handle.close()
    seqdict = {}
    for seq in sequences:
        seqdict[seq.id] = seq
    return seqdict

def obtainPrimerDescriptor(infile, numEntries):
    handle = open(infile)
    sequences = []
    targets = []
    for line in handle:
        splitline = line.split('\t')
        newseq = Seq(splitline[1], generic_dna)
        newrec = SeqRecord(newseq, id=splitline[0])
        sequences.append(newrec)
        targets.append(splitline[2].strip())

    buildingblockprimerdict = {}
    for i in range(numEntries):
        buildingblockprimerdict[targets[i]] = [sequences[i]]
    for i in range(numEntries,2*numEntries):
        buildingblockprimerdict[targets[i]].append(sequences[i])

    positionprimerdict = {}
    for i in range(2*numEntries,3*numEntries):
        positionprimerdict[targets[i]] = [sequences[i]]
    for i in range(3*numEntries,4*numEntries):
        positionprimerdict[targets[i]].append(sequences[i])

    plateprimerdict = {}
    for i in range(4*numEntries,5*numEntries):
        plateprimerdict[targets[i]] = [sequences[i]]
    for i in range(5*numEntries,6*numEntries):
        plateprimerdict[targets[i]].append(sequences[i])

    return buildingblockprimerdict, positionprimerdict, plateprimerdict

def obtainChipPrimers(infile):
    sequences = []
    handle = open(infile)
    for seqrec in SeqIO.parse(handle, "fasta"):
        sequences.append(seqrec)
    handle.close()

    oligodictionary = {}
    for seqrec in sequences:
        tempkey = seqrec.id[0:seqrec.id.rfind('-')]
        if oligodictionary.has_key(tempkey):
            oligodictionary[tempkey].append(seqrec)
        else:
            oligodictionary[tempkey] = [seqrec]

    return oligodictionary

def removePlatePrimers(oligodict, plateprimerdict):
    newoligodict = {}
    for key in oligodict:
        tempnewoligos = []
        foundallprimers = True
        for oligo in oligodict[key]:
            if not str(oligo.seq[0:20]) == str(plateprimerdict[key][0].seq):
                print 'Error: Wrong Plate Primer'
                print oligo.seq[0:20]
                print plateprimers[0].seq
                foundallprimers = False
                continue
            if not str(oligo.seq[-20:]) == str(plateprimerdict[key][1].seq.reverse_complement()):
                print 'Error: Wrong Plate Primer'
                print oligo.seq[-20:]
                print plateprimers[1].seq.reverse_complement()
                foundallprimers = False
                continue
            tempnewoligos.append(SeqRecord(oligo.seq[20:-20], id=oligo.id))
        newoligodict[key] = tempnewoligos
        if foundallprimers:
            print "Successfully found Plate primers for " + key
    return newoligodict

def removePosSpecPrimers(oligodict, posprimerdict):
    newoligodict = {}
    for key in oligodict:
        tempnewoligos = []
        foundallprimers = True
        for oligo in oligodict[key]:
            if not str(oligo.seq[0:20]) == str(posprimerdict[key][0].seq):
                print 'Error: Wrong Position Specific Primer'
                print oligo.seq[0:20]
                print posprimerdict[key][0].seq
                foundallprimers = False
                continue
            if not str(oligo.seq[-20:]) == str(posprimerdict[key][1].seq.reverse_complement()):
                print 'Error: Wrong Position Specific Primer'
                print oligo.seq[-20:]
                print posprimerdict[key][1].seq.reverse_complement()
                foundallprimers = False
                continue
            tempnewoligos.append(SeqRecord(oligo.seq[20:-20], id=oligo.id))
        newoligodict[key] = tempnewoligos
        if foundallprimers:
            print "Successfully found Position primers for " + key

    return newoligodict

def digestOligos(oligodict):
    newoligodict = {}
    for key in oligodict:
        tempnewoligos = []
        restenzstr = key.split('-')[1]
        restenz = vars(Restriction)[restenzstr]
        for oligo in oligodict[key]:
            newseq = restenz.catalyse(oligo.seq)[1]
            tempnewoligos.append(SeqRecord(newseq, oligo.id))

        newoligodict[key] = tempnewoligos
    return newoligodict

def simulateAssembly(oligodict):
    newseqdict = {}
    newoverlapdict = {}
    for key in oligodict:
        growingseq = ""
        overlaps = []
        maxLengthOfOverlap = 50
        for oligo in oligodict[key]:
            matchvector = [False]*maxLengthOfOverlap
            #print 'Growingseq: ' + str(growingseq)
            #print 'oligoseq: ' + str(oligo.seq)
            if growingseq == "":
                growingseq = oligo.seq
            else:
                for i in range(len(matchvector)):
                    if str(oligo.seq[0:1+i])==str(growingseq[(-1*i)-1:]):
                        #print 'equality: ' + str(oligo.seq[0:1+i]) + '\t' + str(growingseq[(-1*i)-1:])
                        matchvector[(-1*i)-1] = True
                overlapindex = maxLengthOfOverlap-matchvector.index(True)
                growingseq = growingseq + oligo.seq[overlapindex:]
                #print 'added to growing seq: ' + str(oligo.seq[overlapindex:])
                overlaps.append(oligo[0:overlapindex])
                #print 'added to overlaps: ' + str(oligo.seq[0:overlapindex])
            #print ""
        newseqdict[key] = SeqRecord(growingseq, id=key)
        newoverlapdict[key] = overlaps
    return newseqdict, newoverlapdict


def findBBSpecificPrimers(assembleddict, buildingblockprimerdict):
    for key in assembleddict:
        assembledgene = assembleddict[key].seq
        forwardprimer = buildingblockprimerdict[key][0].seq
        reverseprimer = buildingblockprimerdict[key][1].seq.reverse_complement()
        foundprimers = True
        if not assembledgene.count(str(forwardprimer))==1:
            foundprimers = False
        if not assembledgene.count(str(reverseprimer))==1:
            foundprimers = False
        if foundprimers:
            print "Successfully found BB Specific Primer for " + key
        else: 
            print "ERROR in finding BB Specific Primer for " + key
            print assembledgene
            print forwardprimer
            print reverseprimer

def findBuiltSeq(assembleddict, referencedict):
    for key in assembleddict:
        genename = key.split('-')[0]
        assembledgene = assembleddict[key].seq
        referencegene = referencedict[genename].seq
        if assembledgene.count(str(referencegene)) == 1:
            print "Sucessful assembly of " + key
        else:
            print "ERROR in assembly of " + key
            print assembledgene
            print referencegene

def runChecks(configDict):

    # read in chip file and primer descriptor file and synthesis files
    # separate oligo's based on assembly
    try:
        output_oligos_file = outputpath + "".join(s for s in configDict["buildSequencesFile"].split("/")[-1].split(".")[:-1]) + "-oligo-output.fasta"
        output_primers_file = outputpath + "".join(s for s in configDict["buildSequencesFile"].split("/")[-1].split(".")[:-1]) + "-primer-output.txt"
        desired_constructs_to_synthesize_file = configDict["buildSequencesFile"]
        finalsynthconstructs = obtainSynthDict(desired_constructs_to_synthesize_file)
        buildingblockprimerdict, positionprimerdict, plateprimerdict = obtainPrimerDescriptor(output_primers_file, len(obtainBuildSequences(configDict["buildSequencesFile"])))
        oligodict = obtainChipPrimers(output_oligos_file)
    except:
        print "\n\nThere were problems decomposing some sequences."
        return
    
    print "checks:\n"
    if configDict["fixedPrimerSetThroughoutFile"] == "False":
        mppoligodict = removePlatePrimers(oligodict, plateprimerdict)
        mpspmppoligodict = removePosSpecPrimers(mppoligodict, positionprimerdict)
        digestedoligosdict = digestOligos(mpspmppoligodict)
        assembledseqdict, overlapdict = simulateAssembly(digestedoligosdict)
        findBBSpecificPrimers(assembledseqdict, buildingblockprimerdict)
        findBuiltSeq(assembledseqdict, finalsynthconstructs)
    else:
        print "Not checking assembly since this file uses a fixed primer set throughout."
    
    print "\n\n"

# run the program
if __name__ == '__main__':
    if sendEmails:
        sendEmail(emailAddressTo, "INITIAL_EMAIL_TEXT.txt")
    
    configDictList = config["configDictList"]
    print "Processing %i input files..." % len(configDictList)

    for entry in configDictList:
        configDict = entry
        run_gasp(configDict)
        runChecks(configDict)
        prefix = "".join(s for s in configDict["buildSequencesFile"].split("/")[-1].split(".")[:-1])
        attachmentfiles = []
        for infile in glob.glob(outputpath + prefix + '*.fasta') + glob.glob(outputpath + prefix + '*.txt'): 
            attachmentfiles.append(infile)
        if sendEmails:
            sendEmail(emailAddressTo, "SECOND_EMAIL_TEXT.txt", attachmentfiles)
    
    # output the file to upload to Agilent
    sequences = []
    for infile in glob.glob(outputpath + '*.fasta'):
        handle = open(infile)
        for seqrec in SeqIO.parse(handle, "fasta"):
            sequences.append(seqrec)
        handle.close()
    fileout = open("output-oligos-and-primers/agilent-upload.txt","w")
    for seqrec in sequences:
        line = seqrec.id + '\t' + str(seqrec.seq) + '\n'
        fileout.write(line)
    fileout.close()
    if sendEmails:
        sendEmail(emailAddressTo, "THIRD_EMAIL_TEXT.txt", [outputpath + "agilent-upload.txt"])
    
    
