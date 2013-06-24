#!/usr/bin/python

# import string
# import threading
import time
from time import gmtime, strftime
import glob
import fileinput
import sys

# For HTML escaping/unescaping
import cgi

import subprocess
from subprocess import Popen

DATADIR = sys.argv[1]
FILES = glob.glob(DATADIR + '*.xml')

for f in FILES:
    # print 'Current f :', f
    fparts = f.split("/")
    fname = fparts[-1].replace('.xml' , '.rdf')
    print "Processing: " + f
    print "Will write to: ../data/" + fname
    wgetcmd = 'curl "http://localhost:8270/xbin/ml.xqy?marcxmlloc=' + f + '" > ../data/' + fname
    
    xresult, xerrors = Popen([wgetcmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True).communicate()
    if xresult == "":
       out = cgi.escape(xerrors)
    else:
        out = xresult

    print out
