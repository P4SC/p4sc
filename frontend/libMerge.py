#!/usr/bin/env python

""" P4SC library: libMerge.py
    This file provides fundamental functions of merging SFCs
    Author: XiangChen, 2018.3.23
"""

import os
import sys
import argparse
import commands
import time
import datetime
import math
import psutil

from lcsSrc.lcs import *
from tableCmpSrc.genTopoOrder import *

""" P4SC LCS algorithm, used to merge two SFCs
"""
def merge(l1,l2):

	# Running key algorithm
	lists = lcs(l1, l2)
	
	if lists == [[]]:
		print "The lcs list is empty, so simply merge the two orders.\n"
		return l1+l2
	else:
		print "Found the lcs order set."

	"""Choose the first order in the lcs order list based on value file"""
	lcsOrder = lists[0]

	"""Merge the two topologic orders"""

	# Here we create a set named "First" to record the previous variables 
	# in the set of insert list(insl), i.e.the variables before the first
	# common LCS variable.
	#
	# To handle the First set, we insert it before the place where the 
	# first lcs variable occurs.

	basel, insl = [], []
	if len(l1) >= len(l2):
		basel, insl = l1, l2
	else:
		basel, insl = l2, l1

	# the first lcs variable
	first_lcs_val = lcsOrder[0]

	# the index of first lcs variable in base list
	first_lcs_val_idx_in_basel = 0
	for base_idx in range(len(basel)):
		if basel[base_idx] == first_lcs_val:
			first_lcs_val_idx_in_basel = base_idx
			break

	# initial mergedl: merged list 
	mergedl = basel
	first_lcs_val_idx_in_mergedl = first_lcs_val_idx_in_basel



	# Here we start to divide the insert list into two parts: 
	# the first set and the other parts of insert list.


	### 1.calculate the first set and the corresponding index
	
	first_set = []
	first_lcs_val_idx_in_insl = 0
	for insl_idx in range(len(insl)):
		if insl[insl_idx] == first_lcs_val:
			first_lcs_val_idx_in_insl = insl_idx
			break
		else:
			first_set.append(insl[insl_idx])

	### 2.handle the first set 

	if first_set == []:
		print "Warning: The first set is empty. Ignoring the handling of first set.", '\n'
		pass
	else:
		# insert to the place before first lcs variable in merged list
		insert_base = first_lcs_val_idx_in_mergedl
		for insert_idx in range(len(first_set)):
			insert_hdl = insert_base+insert_idx
			mergedl.insert(insert_hdl, first_set[insert_idx])

		# update the place index of the index of first lcs variable in merged list
		first_lcs_val_idx_in_mergedl += len(first_set)


	# current insl   : [first_set] [first value of lcs order] [other elements]
	# current mergedl: [first_set] [first value of lcs order] [other elements]
	# Now we start to merge insl to mergedl based on lcs order sequence

	### 3.handle the other parts of insert list

	# the movp points to the first lcs val in merged list at beginning
	# movp is used to traverse >> mergedl << and indicate current element
	movp = first_lcs_val_idx_in_mergedl+1

	# we decide that if current value is also the top value of mergedl,
	# the converter pops it and move movp to the place of current value
	# in mergedl

	# initialization: the original lcs order value has been used to decide
	# the begin of following loop
	isEmpty = False

	del lcsOrder[0]
	# the lcsOrder is empty
	if lcsOrder == []: 
		topVal, isEmpty = 0, True
	else:
		topVal = lcsOrder[0]

	# start from the first value after the first lcs value on mergedl
	startIdx = first_lcs_val_idx_in_insl+1

	for insert_idx in range(startIdx, len(insl)):
		# the current value of >> insl << 
		current_val = insl[insert_idx]

		# if the current value is in the lcsOrder, move the movp to 
		# the place of current value in >> mergedl << 
		if current_val == topVal and not isEmpty:

			# remove topVal from lcs order and update topVal
			lcsOrder.remove(topVal)
			if lcsOrder == []:
				pass
			else:
				topVal = lcsOrder[0]

			# move movp to current_val in >> mergedl << 
			for i in range(movp,len(mergedl)):
				if mergedl[i] == current_val:
					# move to the next place after current vaule in >> mergedl << 
					movp = i+1
					break

				# if not found, raise error(this program has bug, please contact me)
				if i == len(mergedl)-1:
					print "Error: current_val not found in mergedl."
					return

		# otherwise, insert it to >> mergedl << 
		else:
			mergedl.insert(movp, current_val)
			movp += 1

	return mergedl

""" Merge files on assigned directory
"""
def run_merge_sfcs(sfc_files, result_f_name, test_num):

	start = datetime.datetime.now()

	"""merge mechanism:"""

	# copy the first sfc
	f1_name, fidx = sfc_files[0], 0
	cmd = "cp -r %s %s" % (f1_name, result_f_name)
	status, output = commands.getstatusoutput(cmd)
	if status != 0:
		print "\nError occurred as copying result.txt.\n"
		print output
		return

	# merge other sfcs, and store the results on "results.txt"(result_f)
	# merge time = total number of DAG -1
	mergeTime, mergedl = test_num-1, []

	for i in range(mergeTime):
		# open result_f and current file
		result_f = open(result_f_name)
		fidx = i+1
		f_name = sfc_files[fidx]
		f = open(f_name)

		# read contents from result_f and current file
		content1 = result_f.read().split("\n")
		l1 = [int(j) for j in content1[0].split(",")]
		content2 = f.read().split("\n")
		l2 = [int(j) for j in content2[0].split(",")]

		# close files
		result_f.close()
		f.close()
		
		# merge two lists
		mergedl = merge(l1,l2)
		if mergedl == None:
			print "Error: mergedl is empty!"
			print "Some errors occurred in merge(), libMerge.py"
			break

		# write mergedl to result_f
		mergedl_str = ""
		for s in mergedl:
			mergedl_str += str(s)
			mergedl_str += ","
		mergedl_str = mergedl_str[:-1]

		print mergedl, '\n'

		cmd = "echo %s > %s" % (mergedl_str, result_f_name)
		status, output = commands.getstatusoutput(cmd)
		if status != 0:
			print "\nError occurred as writing merged topoOrder!\n"
			print output
			return

	end = datetime.datetime.now()
	print "Total time:", (end-start)

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='libMerge.py')
	parser.add_argument('-n', '--num', help='Test number',
	                    type=int, action="store", default=2)
	parser.add_argument('-d', '--dir', help='Output directory name',
	                    type=str, action="store", default="test")
	args = parser.parse_args()

	if args.dir[-1] is not "/":
		args.dir += "/"

	# get all the sfcs described in .txt files
	requests = os.listdir(args.dir)
	sfc_files = []
	for item in requests:
		# ignore non-request
		if ".txt" not in item:
			continue
		f_name = args.dir+item
		sfc_files.append(f_name)

	result_f_name = args.dir+"result.txt"

	run_merge_sfcs(sfc_files, result_f_name, args.num)
