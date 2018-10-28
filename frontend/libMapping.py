#!/usr/bin/env python

""" P4SC library: libMapping.py
    This file converts midend SFC file based on mapping.txt
    Author: XiangChen, 2018.3.23
"""

import argparse
import commands
from includes import *

""" Hint:
    The mapping file indicates the mapping between the number of NF and NF name.
    A midend sfc file indicates a SFC using NF number sequence.
"""

""" Write content to file
"""
def write_content_to_file(file, content):
    cmd = "echo %s > %s" % (content, file) 
    status, output = commands.getstatusoutput(cmd)
    if status != 0:
        print "\nError: cannot write %s to %s!\n" % (content, file)
        print output
        return

""" Convert NF number to NF name
"""
def convert_number_to_name(file, mapping):
    # read content from result file
    content_str, content = "", []
    with open(file, "r") as f:
        content_str = f.read().split("\n")[0]
        content = [int(i) for i in content_str.split(",")]
    # represent them in new format(i.e.replace number with NF name)
    sfc_str = ""
    for element in content:
        index = element
        NF_name = mapping[index]
        sfc_str += NF_name
        sfc_str += ","
    sfc_str = sfc_str[0:-1]
    # write new content to file
    write_content_to_file(file, sfc_str)

""" Convert NF name to NF number
"""
def convert_name_to_number(file, mapping):
    # read content from result file
    content_str, content = "", []
    with open(file, "r") as f:
        content_str = f.read().split("\n")[0]
        content = [str(i) for i in content_str.split(",")]
    # represent them in new format(i.e.replace NF name with number)
    sfc_str = ""
    for element in content:
        NF_num = mapping.index(element)
        sfc_str += str(NF_num)
        sfc_str += ","
    sfc_str = sfc_str[0:-1]
    # write new content to file
    write_content_to_file(file, sfc_str)

""" Read NF mapping from mapping file
"""
def read_mapping():
    mapping = [0]
    mapping += nfs
    return mapping

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='libMapping.py')
    parser.add_argument('-f', '--file', help='Midend SFC file',
                        type=str, action="store", required=True)
    parser.add_argument('-c', '--case', help='case=1: convert name to number, case=2: convert number to name',
                        type=int, action="store", default=0)
    args = parser.parse_args()

    mapping = read_mapping()
    if args.case == 1:
        sfc_str = convert_name_to_number(args.file, mapping)
    elif args.case == 2:
        sfc_str = convert_number_to_name(args.file, mapping)
    else:
        print "Do nothing."
