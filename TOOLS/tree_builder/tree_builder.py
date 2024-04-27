#! /usr/bin/env python3

# read a tree of files with _CORE_ and _PLATFORM_ macros
# and reproduce it with them changed to the actual core and platform names
#
# args
# --template - directory with the template files
# --dest     - directory to write
# --core     - replacement for _CORE_
# --platform - replacement for _PLATFORM_
#
# --write    - actually writes the files
# --delete   - deletes all the old files first

import argparse
import os.path
import sys
import shutil
import json
import re

def getInt(jsonElement):
    if isinstance(jsonElement, int):
        return jsonElement
    if isinstance(jsonElement, str):
        return int(jsonElement,0)

    raise Exception(f"'{jsonElement}' cannot be parsed to an int")

def jsonPath(jsonDict, path, default=None):
    current = jsonDict
    for element in path.split("."):
        if isinstance(current, list):
            try:
                index = int(element)
                current = current[index]
            except:
                current = None
        elif isinstance(current, dict):
            current = current.get(element, None)

        if current is None:
            break

    return default if current is None else current

def checkInteractFile(dataFile, filename, args):
    print(f"Checking interact file '{filename}'")

    # ensure that ids are unique, default values for lists
    # are from the possible values, values are unique and
    # masks are appropriate and don't overlap

    # map of addresses to used bits
    addresses = dict()

    # set of IDs used to the element names
    ids = dict()

    for variable in jsonPath(dataFile, "interact.variables", default=[]):
        name = jsonPath(variable, "name")
        assert name is not None, "all variables must have a name"
        id = jsonPath(variable, "id")
        assert id is not None, f"element {name} does not have an ID"
        id = getInt(id)
        type = jsonPath(variable, "type")
        assert type in ["list", "radio" , "check" , "slider_u32" , "number_u32" , "action"], f"Element '{name}' has invalid type: {type}"
        address = jsonPath(variable, "address")
        assert address is not None, f"Element '{name}' does not have an address"
        address = getInt(address)
        mask = getInt(jsonPath(variable, "mask", 0))

        assert not id in ids, f"element '{name}' has the same id: {id} as element {ids[id]}"
        ids[id] = name

        usedBits = addresses.get(address, 0)

        # invert the mask
        notMask = 0xffffffff ^ mask

        assert usedBits & notMask == 0, f"element: {name} has mask 0x{mask:08x} but address: {hex(address)} already uses bits 0x{usedBits:08x}"
        addresses[address] = usedBits | notMask

        # if it's a list is must have a default value and options and they must
        # all be unique and fit in the mask

        if type == "list":
            defaultval = jsonPath(variable, "defaultval")
            assert defaultval is not None, f"Element '{name}' does not have a default value"
            defaultval = getInt(defaultval)

            options = dict()
            for option in jsonPath(variable, "options", []):
                optionName = jsonPath(option, "name")
                assert optionName is not None, f"one of the options for '{name}' does not have a name"
                optionValue = jsonPath(option, "value")
                assert optionValue is not None, f"option '{optionName}' for '{name}' does not have a value"
                optionValue = getInt(optionValue)
                assert optionValue & notMask == optionValue, f"option '{optionName}' for '{name}' has value 0x'{optionValue:08x}' which does not fit the mask 0x'{mask:08x}'"
                assert options.get(optionValue) is None, f"option '{optionName}' for element '{name}' is the same as '{options[optionValue]}'"
                options[optionValue] = optionName

            # finally check the default is a valid option
            assert defaultval in options, f"defaultval 0x{defaultval:08x} is not a valid option for element '{name}'"

def checkCoreFile(dataFile, filename, args):
    print(f"Checking core file '{filename}'")

    assert(jsonPath(dataFile, "core.metadata.shortname") == args.shortname)
    assert(jsonPath(dataFile, "core.metadata.author") == args.author)
    assert(args.platform in jsonPath(dataFile, "core.metadata.platform_ids"))

CHECKS = {
    r'.*/core.json$': checkCoreFile,
    r'.*/interact.json$' : checkInteractFile,
    r'.*/Interact/.*json$' : checkInteractFile
}

def translate(x, args):
    x = x.replace("_PLATFORM_", args.platform)
    x = x.replace("_CORE_", f"{args.author}.{args.shortname}")
    return x

def process(entry, templatePath, targetPath, args):

    (path, dirs, files) = entry
    rel = os.path.relpath(path, templatePath)
    target = os.path.join(targetPath, rel)
    components = [translate(x, args) for x in rel.split(os.path.sep)]

    target = os.path.join(targetPath, *components)

    level = 0 if "." in components else len(components)

    def log(message, force=False):
        if(args.verbose or force):
            print(f"{'  ' * level}{message}")

    log(f"reading {path}")
    log(f"writing {target}")

    # ensure the target directory exists and list any files in it
    os.makedirs(target, exist_ok=True)

    # use walk as an easy way to get the files and directories
    currentTargetFiles = set(filter(lambda x:not x.startswith("."), next(os.walk(target))[2]))

    # copy all the files from source to target
    for file in files:
        if file.startswith("."):
            continue

        file_translated = translate(file,args)

        fullSource = os.path.join(path, file)
        for (check, routine) in CHECKS.items():
            if re.match(check, fullSource):
                with open(fullSource) as f:
                    routine(json.load(f), fullSource, args)

        if args.write:
            shutil.copy(fullSource, os.path.join(target, file_translated))
            log( f"Copied: '{os.path.join(path, file)}' to '{os.path.join(target, file)}'")
        else:
            log( f"Would Copy: '{os.path.join(path, file)}' to '{os.path.join(target, file)}'")

        currentTargetFiles.discard(file)

    if args.delete:
        for file in currentTargetFiles:
            if args.write:
                log("Removing: {os.path.join(target,file)}")
                os.remove(os.path.join(target, file))
            else:
                log("Would remove: {os.path.join(target,file)}")



parser = argparse.ArgumentParser( "tree_builder", "build the tree of files we need for distribution")

parser.add_argument( "--template", help="directory for the template files with _CORE_ and _PLATFORM_ entries", type=str,  default="dist" )
parser.add_argument( "--target", help="directory to write the new file structure", type=str,  default="ROOT" )
parser.add_argument( "--author", help="e.g. rolandking", type=str, required=True )
parser.add_argument( "--shortname", help="e.g. Athena", type=str, required=True )
parser.add_argument( "--platform", help="e.g. athena", type=str, required=True )
parser.add_argument( "--verbose", "-v", action="store_true", default=False)

parser.add_argument( "--write", help="actually write and not just log", action="store_true", default=False)
parser.add_argument( "--delete", help="remove old leaf files", action="store_true", default=False)

args = parser.parse_args()

# first make sure the source exists and is a directory
templatePath = os.path.abspath(args.template)
if not os.path.isdir(templatePath):
    print( f"ERROR - template path: {args.template} ({templatePath}) is not a directory")
    sys.exit(1);

# if we are writing and deleting and the target exists ensure that it
# is parallel to the template directory and rooted at CWD before we blow
# it away
targetPath = os.path.abspath(args.target)
if args.write:
    try:
        os.makedirs(targetPath, exist_ok=True)
    except Exception as e:
        print(f"Unable to create the target directory f{targetPath} [{e}]")

# now walk the source path passing arguments to the processing function
for entry in os.walk(templatePath):
    process(entry, templatePath, targetPath, args)
