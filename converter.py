#!/usr/bin/env python

""" P4SC library: converter.py
    This file parses input requests and merges them to result.txt
    Author: XiangChen, 2018.3.24
"""

import os
import sys
import argparse
import commands

from frontend.libMerge import *
from frontend.libMapping import *

def copyFiles(f_name, copyf_name):
	# copy the file
	cmd = "cp -r %s %s" % (f_name, copyf_name)
	status, output = commands.getstatusoutput(cmd)
	if status != 0:
		print "\nError occurred as copying file %s.\n" % f_name
		print output
		return

def removeFilesFromDir(dir):
	# remove temporary files
	all_files = os.listdir(dir)
	for f in all_files:
		if "tmp_" not in f:
			continue
		else:
			cmd = "rm %s" % (dir+f)
			status, output = commands.getstatusoutput(cmd)
			if status != 0:
				print "\nError occurred as removing file %s.\n" % f_name
				print output
				return

def converter(dir):
	if dir[-1] is not "/":
		dir += "/"

	# read mapping from mapping file
	mapping = read_mapping()

	# get all the sfcs described in .txt files
	requests = os.listdir(dir)
	sfc_files = []
	for item in requests:
		# ignore non-request
		if ".txt" not in item:
			continue
		f_name = dir+item
		
		# introduce a replica of input request file
		copyf_name = dir+"tmp_"+item

		# copy the request file
		copyFiles(f_name, copyf_name)

		sfc_files.append(copyf_name)

		# convert this file to midend SFC file
		convert_name_to_number(copyf_name, mapping)

	sfc_num = len(sfc_files)
	
	# no such file
	if sfc_num == 0:
		print "Error: no such file to merge."
		return

	# only one sfc
	elif sfc_num == 1:
		result_f_name = dir+"result.txt"
		copyFiles(sfc_files[0], result_f_name)
		
		# recover NF sequences
		convert_number_to_name(result_f_name, mapping)
		print "Successfully, please check the results in %s" % result_f_name

		# remove temporary files
		removeFilesFromDir(dir)

	# merge multiple SFCs
	else:
		# merge the SFCs and store the result in result.txt
		result_f_name = dir+"result.txt"
		run_merge_sfcs(sfc_files, result_f_name, sfc_num)

		# recover NF sequences
		convert_number_to_name(result_f_name, mapping)
		print "Successfully, please check the results in %s" % result_f_name

		# remove temporary files
		removeFilesFromDir(dir)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='converter.py')
    parser.add_argument('-d', '--dir', help='Directory of input requests',
                        type=str, action="store", required=True)
    args = parser.parse_args()
    converter(args.dir)
