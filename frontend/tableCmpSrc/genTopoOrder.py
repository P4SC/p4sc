#!/usr/bin/env python

import random
import numpy
import argparse
import commands

def genTopoOrder():
	# base list
	base = list(range(1,16))
	# set list length randomly
	l1_len = random.randint(1, 15)
	l2_len = random.randint(1, 15)
	# slice the lists randomly
	slice1 = random.sample(base, l1_len)
	slice2 = random.sample(base, l2_len)
	# generate input strings
	string1, string2 = "", ""
	for i in slice1:
		string1 += str(i)
		string1 += ","
	string1 = string1[:-1]
	for i in slice2:
		string2 += str(i)
		string2 += ","
	string2 = string2[:-1]
	return string1, string2

"""Return the topo order in terms of list and string
"""
def genTopoOrder2():
	# base list
	base = list(range(1,16))
	# set list length randomly
	l1_len = random.randint(1, 15)
	# slice the lists randomly
	slice1 = random.sample(base, l1_len)
	# generate input strings
	string1 = ""
	for i in slice1:
		string1 += str(i)
		string1 += ","
	string1 = string1[:-1]
	return slice1, string1

if __name__ == '__main__':
	genTopoOrder()