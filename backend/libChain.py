#!/usr/bin/env python

import argparse
from time import sleep
import os
import commands
import datetime
import math
import psutil

def read_chain(path):
    ingress = []
    egress = []
    words = []
    with open(path, "r") as f:
        line = f.readline()[:-1]
        words = line.split()

        if len(words) != 3 :
            print "Error: Missing ingress pipeline"
            os._exit(0)

        haveegress = False
        for line in f:
            if not f: 
                print "Error: Missing egress pipeline"
                os._exit(0)
            words = line.split()

            if len(words) == 0:
                continue

            if len(words) >= 3:
                if words[0] == "//" and len(words) == 3: 
                    haveegress = True
                    break
                else:
                    print "Error: Format error. Please check README carefully."

            assert(len(words) == 1)

            if words[0] in ingress:
                print "Error: Block already used"
                os._exit(0)
            ingress.append(words[0])

        if not haveegress:
            print "Error: Missing egress pipeline"
            os._exit(0)

        for line in f:
            if not f: break
            words = line.split()
            if len(words) == 0:
                continue
            assert(len(words) == 1)
            if words[0] in ingress or words[0] in egress:
                print "Error: Block already used"
                os._exit(0)
            egress.append(words[0])

    return ingress, egress

def gen(path):
    ingress, egress = read_chain(path)

    cmd = "./reset.sh"
    status, output = commands.getstatusoutput(cmd)

    cmd = "cat ./src/ingress1.txt >> src/control_flow.p4"
    status, output = commands.getstatusoutput(cmd)

    for block in ingress:
        statement = "\"%s();\"" % block
        cmd = "./src/insert.sh %s" % statement
        status, output = commands.getstatusoutput(cmd)

    cmd = "cat ./src/ingress2.txt >> src/control_flow.p4"
    status, output = commands.getstatusoutput(cmd)

    cmd = "cat ./src/egress1.txt >> src/control_flow.p4"
    status, output = commands.getstatusoutput(cmd)

    for block in egress:
        statement = "\"%s();\"" % block
        cmd = "./src/insert.sh %s" % statement
        status, output = commands.getstatusoutput(cmd)

    cmd = "cat ./src/egress2.txt >> src/control_flow.p4"
    status, output = commands.getstatusoutput(cmd)

    cmd = "./src/build.sh"
    status, output = commands.getstatusoutput(cmd)

    cmd = "p4-validate switch.p4"
    status, output = commands.getstatusoutput(cmd)
    print output

def test():
    for i in range(10):
        idx = i+1
        gen("./test/test%d.txt"%idx)
        sleep(1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='libChain.py')
    parser.add_argument('-p', '--path', help='Path to configuration file',
                        type=str, action="store", default="./test/chain.txt")
    args = parser.parse_args()
    gen(args.path)

    # test()
