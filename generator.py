#!/usr/bin/env python

""" P4SC library: generator.py
    This file parses result.txt and converts it to backend/switch.p4
    Author: XiangChen, 2018.3.24
"""

import os
import sys
import argparse
import commands

from frontend.libMerge import *
from frontend.libMapping import *
from frontend.includes import *
from backend.libChain import *

def generator(file):
    """write chain.txt based on midend sfc files and mapping.txt"""

    # read content from midend sfc file
    content_str, content = "", []
    with open(file, "r") as f:
        content_str = f.read().split("\n")[0]
        content = [str(i) for i in content_str.split(",")]

    # TBD: this step requires to copy block files in backend/blocks.
    # It is complex because you have to rename the components of P4
    # program to avoid compiling errors.

    # Here I simply remove duplicate nodes from sfc contents. 
    # It does not correspond to our paper descriptions, but it works ;)
    sortKey = content.index
    content = list(set(content))
    content.sort(key=sortKey)

    # populate ingress codes and egress codes based on nf name
    p4_ing_codes, p4_eg_codes = [], []
    for item in content:
        ing_code = p4_ing_code_map.get(item)
        eg_code = p4_eg_code_map.get(item)
        if ing_code is not None:
            p4_ing_codes.append(ing_code)
        if eg_code is not None:
            p4_eg_codes.append(eg_code)
        if ing_code is None and eg_code is None:
            print "Error: %s does not have a block!" % item
            return

    """go to the directory of backend/ and reset environment"""

    # go to the directory of backend
    os.chdir("./backend")

    # reset environment
    cmd = "./reset.sh"
    status, output = commands.getstatusoutput(cmd)


    """create chain.txt and write control flow codes to it"""

    # create chain.txt
    cmd = "touch chain.txt"
    status, output = commands.getstatusoutput(cmd)
    if status != 0:
        print output
        return

    # write ingress codes
    cmd = "echo \"// ingress pipeline\" >> chain.txt"
    status, output = commands.getstatusoutput(cmd)
    if status != 0:
        print output
        return

    for item in p4_ing_codes:
        cmd = "echo \"%s\" >> chain.txt" % item
        status, output = commands.getstatusoutput(cmd)
        if status != 0:
            print output
            return

    # write egress codes
    cmd = "echo \"// egress pipeline\" >> chain.txt"
    status, output = commands.getstatusoutput(cmd)
    if status != 0:
        print output
        return

    for item in p4_eg_codes:
        cmd = "echo \"%s\" >> chain.txt" % item
        status, output = commands.getstatusoutput(cmd)
        if status != 0:
            print output
            return

    # generate P4 program
    gen("./chain.txt")

    print "\nSuccessfully generate P4 program on backend/switch.p4 !\n"

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='converter.py')
    parser.add_argument('-f', '--file', help='Midend sfc file',
                        type=str, action="store", required=True)
    args = parser.parse_args()
    generator(args.file)
