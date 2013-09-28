# Genovo ##
Welcome to Genovo World. We are Shenzhen_BGIC_0101_2013 team.
## What we do 
* NeoChr
   > balabala
* NucMod 
   > balabala
* SegmMan
  >balabala


=============================================

## install Guid
Our software are totally based on JBrowse which is next-generation of GBrowse. If you have install JBrowse, just pull git and use.

### Install JBrowse
   > To install JBrowse, see the main JBrowse wiki at http://gmod.org/wiki/JBrowse.
   
   > ### For Short Description: 
   * unzip the Download file in www root folder
   `(/home/www is recommand and  do not use /var/www/ as that need root permission)`
   * cd jbrowse
   * ./install.sh # Install all perl package needed with cpan, If all goes well, you can open http://localhost/jbrowse/index.html?data=sample_data/json/volvox

### Software Requirment 
 * perl5
 * php5 ( for REST api and backend server )
 * Apache
 * Linux ( Tested on Debian )
 * git ( for version control plugin )
 * Biopython and UNAFoldt ( for chip plugin )
 * Blast+ ( for NucleoMod Plugin )
 * ` Chrome, Firefox, and IE10 is recommand`

### Permissoin Requirment
 `Writable data, plugin/tmp_data, server/tmp_data, jbrowse_conf.json`

 `Executable ./bin/  ./server/bin/  ./plugin/bin`

### Install NucleoMod Plugin
> NucleoMod depend on Blast+, So if you use Debian based System:
   `apt-get install ncbi-blast+`
 
> Or you can Install From:
`ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/` 

### Install Chip Plugin
Download and install UNAFoldt and Biopython from:
>  * UnaFold
    	http://dinamelt.rit.albany.edu/download.php
 * Biopython:
		http://biopython.org/DIST/docs/install/Installation.html

### install version control plugin
> `git is needed`

### Any other Plugins is portable

===================================================

## Genovo Server Side Tutrorial

### Folder Structure : 
```
./data/    
   |-NeoChr_5_add          # NeoChr Plugin, name as "NeoChr_{weekday}"
   |---01.whole2mega       # SegmMan plugin  data
   |---02.globalREmarkup   # SegmMan plugin  data
   |---03.mega2chunk2mini  # SegmMan plugin  data
   |---chip_data           # chip design
   |---names               # prefix for search
   |---seq                 # crc32 encode refsequence  name path
   |-----d7f
   |-------417
   |---------f1
   |---tracks             # track display in browser
   |-----gene             # track cluster
   |-------NeoChr         # Genome Name 
   |-----part
   |-------NeoChr
   |-----Transcript
   |-------NeoChr
```
```
 ./server/
   |-bin
   |---chip_new           # create new chip data 
   |-----ols-pool-generation-script
   |-------output-oligos-and-primers
   |---GetPrice           # fetch enzyme price
   |---segmentation       # SegmMod plugin 
   |-config               # plugins config data
   |---features            
   |---geneset
   |---globalREmarkup
   |---markers
   |---Optimize
   |-doc                    # document about plugins
   |-lib                    # library used
   |-pathway                # pathway data used 
   |-REST                   # end-side REST implement
   |-------chip
   |-------features
   |-------modify
   |-------Segmentation
   |-------stats
   |---config
   |-rewire
```

## REST API
```
base_url = server/REST/index.php

# output genes data by refname and pos
GET base_url/features/SearchByLocation?refname&start&end   
POST base_url/features/delete

# output git verison control for unroll data
GET base_url/stats/version/(?<dataset>\w+)

# get pathway resource
GET base_url/pathway/nav

# create and decouple from order genelist data
POST base_url/decouple?refname&

# add loxp, centremele, ARS and so on
POST	/modify/Add

#  SegmMod plugin 
POST 	/Segmentation/globalREmarkup
	        /Segmentation/mega2chunk2mini
	        /Segmentation/whole2mega
GET  	/Segmentation/info
	
# Nucleo plugin
POST     /NucleoMod

# chip plugin
POST	/chip/chip

GET 	/stats/config 

# for get downloadable data information
GET /data/info

```

Besides, our server side implement is flexable. User can config server side data for power usage.


===================================================

# Medals Requirement

##Bronze Medal

*  1 Register the team, have a great summer, and have fun attending the Jamboree
*  2 Create and share a description of the team's project via the iGEM wiki
  * [Overview of project](link)
* 3 Present a Poster and Talk at the iGEM Jamboree.
* 4 Develop and make available via the The Registry of Software Tools an open source software tool that supports synthetic biology based on BioBrick standard biological parts
  * Our software in Github

> Note:
Our giant software aims at operating Biobrick of device level based on synthesized DNA fragments.
> But for biobrick level, the second module can also assist users to design genes, such as deletion of [EcorI, XbaI, SpeI, PstI, Not I in the CDS, codon optimization and repeat smash. ](link_to_module_2)

## Silver Medal

* 1.A Provide a detailed, draft specification for the next version of your software tool.

> As our project is so [large and extensible greatly, at least 5 ideas](link) can't be realized due to time limitation.

*  1.B Provide a second, distinct (yet complementary) software tools project.

> For the third module SegmMan, we have a complementary design & synthesis method OLS chip synthesis(link), so that Genovo is compatible for both synthesizer and chip.

* 2  Provide a demonstration of their software either as a textual or video tutorial made available on their wiki.

> [Textual tutorial](link)

# Gold Medal
* 1 Have another team utilize the software developed by your team. You must clearly show how your software was used and the results that were obtained.

>   
* [We have software team Shenzhen_BGIC_ATCG to use the second module to design their genes](link).
* [SC2.0 project also try out SegmMan module on chrVII’s segmentation](link).

* 2 .A Outline and detail how your software effects Human Practices in Synthetic Biology.

> Share:
* Web-based server for public to use
* Software assessment and comparison with Biostudio.
* Regional workshop

> Innovation:
* [We interview with core leader, Dr. Patrick Yizhi Cai and talk about Genovo’s design and application.](link)
 
> Advertisement:
* [We tried to sell our team shirts to people from BGI.](link_sell) 

* 2 .B Use SBOL in your software documentation.

> We use SBOL as one of the output of first module to describe the genes in new created pathway.

* 3 .A. Develop and document a new technical standard that supports one of the following:

> Design of BioBrick Parts or Devices : 
  * [Chromosome Design Standard](link)
  * [Design Operation Standard](link)

> Construction of BioBrick Parts or Devices : 
  * [Assembly Strategy Standard](link)
