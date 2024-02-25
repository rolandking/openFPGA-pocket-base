#! /usr/bin/env python3

import json
import argparse

parser = argparse.ArgumentParser( "json_reader", "read json files for strings to use in makefiles")

parser.add_argument( "filename", type=str )
parser.add_argument( "path", type=str )

args = parser.parse_args()

with open(args.filename, "+r") as f:

    parsed = json.load(f)

    succeeded = []
    for element in args.path.split('.'):

        if isinstance(parsed, dict):
            if element in parsed:
                parsed = parsed[element]
            else:
                raise RuntimeError(f"Cannot find '{element}' after parsing {'.'.join(succeeded)}")
        elif isinstance(parsed, list):
            if str.isdigit(element):
                parsed = parsed[int(element)]
            elif element == "*":
                parsed = parsed
            else:
                # assume each element is a dictionary and look up the same element in each
                parsed = [ x[element] for x in parsed ]
        else:
            raise RuntimeError( f"Parsed '{succeeded}' ends with a '{type(parsed)}', cannot subscript" )
         
        succeeded.append(element)
        
    if isinstance(parsed, str):
        print( parsed )
    elif isinstance(parsed, list):
        print( " ".join( [str(x) for x in parsed ] ))
    else:
        raise RuntimeError( f"Parsed '{succeeded}' finished with a {type(parsed)}, cannot print" )

