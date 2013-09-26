# Installing Genovo

## Software Requirment 
	# Basic
	perl 
	python
	Apache
	# Features
	git (for version control plugin)
	php (for REST api and backend server)
	Biopython and UNAFoldt (for chip plugin)
	Blast+ (for NucleoMod Plugin)

## Permissoin Requirment
	Write in data/
	Write plugin/tmp_data
	Write server/tmp_data 

## Install JBrowse
	To install JBrowse, see the main JBrowse wiki at http://gmod.org/wiki/JBrowse.

### For Short Description
	unzip the Download file
	cd jbrowse
	./install.sh # Install all perl package needed auto with Internet
	# If all goes well, you can open
	#   http://localhost/jbrowse/index.html?data=sample_data/json/volvox

## Install NucleoMod Plugin
	NucleoMod depend on Blast+, So if you use Debian based System:
		apt-get install ncbi-blast+
	Or you can Install From:
		ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ 

## Install Chip Plugin
	Download and install UNAFoldt and Biopython from:
	1、UnaFold
		http://dinamelt.rit.albany.edu/download.php
	2、Biopython:
		http://biopython.org/DIST/docs/install/Installation.html

## Any other Plugins is portable