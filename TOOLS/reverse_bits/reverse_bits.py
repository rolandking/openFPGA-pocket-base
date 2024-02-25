#!/usr/bin/env python3
import sys

# check for 2 arguments, if not, print a usage message
if len(sys.argv) != 3:
    print( f"Usage: {sys.argv[0]} <infile> <outfile>" )
    sys.exit(1)

# read the file

with open(sys.argv[1],"rb") as infile: 
    x = infile.read(-1)

out = bytes([((((y*0x0202020202) & 0x010884422010)%1023)) for y in x])

with open(sys.argv[2], "wb") as outfile:
    outfile.write(out)


