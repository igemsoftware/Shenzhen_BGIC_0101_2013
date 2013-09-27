*The main script is: gasp.py

*The main configuration file is: plate-based-assembly-from-ols-pool-config.json

*Workflow:
**Put input sequence files in the input-seqs directory
**Edit the configuration file, as described below
**Run gasp.py
**Inspect outputs in the output-oligos-and-primers directory

EXPLANATION OF CONFIG FILE:

{
    "initialPlateNum": 4, # 96-well plates holding assembled constructs are numbered starting with this number 
    "buildSequencesFile": "input-seqs/yeast_chr1_3_16.all_bb.fasta", # the location of a fasta file containing seqs for the desired constructs
    "primerOutputFile": "output-files/primer-output.txt", # the location of a txt file which will contain primer sequence outputs
    "oligoOutputFile": "output-files/oligo-output.fasta", # the location of a fasta file which will contain oligo sequence outputs for the OLS pool
    "RESpacing": [ # list of offsets of enzyme cut sites from the end of the corresponding enzyme recognition sites, with enzymes ordered as in REVector
        5, 
        2, 
        5, 
        4
    ], 
    "REVector": [ # list of restriction enzymes that gasp will search through if SearchForRe is set to "True"
        "BsaI", 
        "BtsI", 
        "BsmBI", 
        "BspQI"
    ], 
    "SearchForRE": "True", # set this to "False" if you wish to control the exact restriction site which is used, specified by REToUse. Examples: usually set to "False" for DNA origami 		             scaffold sequences, usually set to "True" for synthetic genes for in-vivo use.
    "REToUse": "", # Restriction enzyme to use if SearchForRE is set to "False", e.g., "BsaI". Leave blank if SearchForRE is set to "True". Usually set to "BsaI" for Shih lab DNA
                     origami scaffold sequences.
    "forwardPrimersLibraryFile": "primer-library/forward_finalprimers.fasta", # Fixed library of ~ 3000 orthogonal forward primers
    "reversePrimersLibraryFile": "primer-library/reverse_finalprimers.fasta", # Fixed library of ~ 3000 orthogonal reverse primers
    "avgoverlapsize": 20, # Average length of overlap region between adjacent oligos
    "deltaGThresholdForOverlaps": -3, # Overlap is rejected if its hybridization free energy in kcal/mol is below this number
    "selfDimersThreshold": 3, # Reject a decomposition if it contains a self-dimer with free energy in kcal/mol below this number
    "insertionSizeToKillRESite": 2, # Leave this set to 2 for now
    "lengthleeway": 10, # Leeway in oligo length that is allowed in searching for acceptable overlaps
    "overlaptemps": [ # Overlap regions must have a melting temperature in this range
        55, 
        65
    ], 
    "positionleeway": 10 # Leeway in junction position that is allowed in searching for acceptable overlaps
}