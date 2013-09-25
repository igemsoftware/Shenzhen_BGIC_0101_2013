import sys
import time
import codecs

pathToGasp = "/home/marblestone/gasp_marblestone/cleaned-up-scripts/"
if not pathToGasp in sys.path:
    sys.path[0] = pathToGasp
print sys.path

from twisted.web.resource import Resource
import cgi
from gaspserver import *
from gaspserver.Gasp import *
import json

class Page(Resource):    
    isLeaf = True
    arguments_submitted = []
    def render_GET(self, request):
        return '''<html>
<head>
</head>
      
<body>

<form method='POST' enctype="multipart/form-data" id="je_sourcetextform">
<h3>Welcome to the Gene Assembly by Sub-Pool PCR (GASP) web server!</h3>
ENTER YOUR NAME: <input type="text" name="username"><br>
ENTER YOUR EMAIL ADDRESS: <input type="text" name="useremail" <br>
ENTER THE INPUT FILE: <input type="file" name="inputfile"><br>
<br><br>
EDIT CONFIGURATION PARAMETERS IN THE BOX BELOW:<br>
<textarea id="je_sourcetextarea" rows="27" cols="60" name="sourcearea">
"initialPlateNum": 2, 
"RESpacing": [
    2,
    5,
    4
],
"REVector": [
    "BtsI",
    "BsmBI",
    "BspQI"
],
"SearchForRE": "True",
"REToUse": "BtsI",
"avgoverlapsize": 20,
"deltaGThresholdForOverlaps": -3, 
"selfDimersThreshold": 3,
"lengthleeway": 10,
"positionleeway": 10,
"oligoSizeMax": 200,
"seqsToAvoidInOverlapRegions":[],
"skip":[]
</textarea>
<br>Note: do not set initialPlateNum to 1, it must be 2 or greater
<br><br>You can download the full version of gasp from the <a href = "https://bitbucket.org/skosuri/gasp/wiki/Home">bitbucket repository</a>. Instructions are <a href = "2011-03-05-GASP-manual-v1.pdf">here</a>.
<p>
<input type="submit" value="Upload Files">\
</p>

</form>

<div id="je_warningdiv">
</div>

</body>
</html>'''
                 
    def render_POST(self, request):
       args = request.args
       print args
       username = args["username"][0].strip("\r\n")
       useremail = args["useremail"][0].strip("\r\n")
       inputfile_contents = args["inputfile"][0]
       jsondata = json.loads("{" + args["sourcearea"][0] + "}")
       configFile = open(pathToGasp + "gaspserver/plate-based-assembly-from-ols-pool-config.json", "r")
       config = json.load(configFile)
       configFile.close()
       for key in jsondata:
           if jsondata[key] != config["configDictList"][0][key]:
               config["configDictList"][0][key] = jsondata[key]
               
       configFile = codecs.open(pathToGasp + "gaspserver/plate-based-assembly-from-ols-pool-config.json", "w", "utf8")
       json.dump(config, configFile, indent = 5)
       configFile.close()
       out = codecs.open(pathToGasp + "gaspserver/input-seqs/inputfile.txt", 'w', 'utf8')
       out.write(inputfile_contents)
       out.close()
       time.sleep(5)
       try:
           g = None
           g = gaspInstance(useremail, pathToGasp)
           g.start()
       except:
           return "<html><body>There was an error.</body></html>"
       return "<html><body>Hello %s:<br>We will be sending an email to %s shortly.</body></html>" % (username, useremail)
       
resource = Page()
