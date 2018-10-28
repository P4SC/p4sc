#!/usr/bin/env python

import argparse
import commands

from tableCmpSrc.genTopoOrder import *
from tableCmpSrc.tableNumCmp import *

def generateTest(directory, test_num):
	"""Generating Topo Order Tests"""
	for i in range(test_num):
		ai = i+1
		# Randomly generate topo order
		l, topoOrder = genTopoOrder2()
		# Write topo order to file
		cmd = "sudo ./createTopoOrder.sh %s %d %s" % (directory, ai, topoOrder)
		status, output = commands.getstatusoutput(cmd)
		if status != 0:
			print "\nError occurred as generating topo order tests!\n"
			print output
			return

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='LCS parsing')
	parser.add_argument('-n', '--num', help='Test number',
	                    type=int, action="store", default=2)
	parser.add_argument('-d', '--dir', help='Output directory',
	                    type=str, action="store", default="test")
	args = parser.parse_args()
	generateTest(args.dir, args.num)