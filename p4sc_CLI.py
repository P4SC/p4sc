#!/usr/bin/env python

""" P4SC library: p4sc_CLI.py
    This file is used to receive user requests of SFC
    Author: XiangChen, 2018.3.25
"""

import argparse
import cmd
import commands
import os
import sys
from dag import DAG, DAGValidationError

from frontend.includes import nfs

class UIn_Error(Exception):
    def __init__(self, info=""):
        self.info = info

    def __str__(self):
        return self.info

class p4scPrompt(cmd.Cmd):
    prompt = 'p4scCmd> '
    intro  = 'Control utility for constructing SFC requests'
    targetDir = ''
    haveAssignedDir = False
    sfcNumber = 1

    dag = DAG()

    def exactly_n_args(self, args, n):
        if len(args) != n:
            raise UIn_Error(
                "Wrong number of args, expected %d but got %d" % (n, len(args))
            )

    def do_list_nfs(self, line):
        """Print avaiable nfs: list_nfs"""
        self.exactly_n_args(line.split(), 0)
        for i in range(len(nfs)):
            print "No.%d NF: %s" % ((i+1), nfs[i])

    def do_assign_dir(self, line):
        """Assign the directory of output sfc requests: assign_dir [dir]"""
        self.exactly_n_args(line.split(), 1)
        targetDir = line
        if targetDir[:-1] == '/':
            targetDir = targetDir[:-1]
        if os.path.isdir(targetDir):
            # go to the directory of targetDir
            # os.chdir(targetDir)
            
            self.targetDir = targetDir
            self.haveAssignedDir = True
        else:
            print "%s not exist" % targetDir

    def do_before(self, line):
        """NF1 before NF2: before [NF1] [NF2]"""
        self.exactly_n_args(line.split(), 2)
        args = line.split()
        isBadInput = False
        if args[0] not in nfs:
            print "%s not in nfs, please check avaiable nfs using \'list_nfs\'" % args[0]
            isBadInput = True
        if args[1] not in nfs:
            print "%s not in nfs, please check avaiable nfs using \'list_nfs\'" % args[1]
            isBadInput = True
        if not isBadInput:
            if args[0] not in self.dag.graph:
                self.dag.add_node(args[0])
            if args[1] not in self.dag.graph:
                self.dag.add_node(args[1])
            self.dag.add_edge(args[0], args[1])

    def do_branch(self, line):
        """NF1 then NF2 or NF3: branch [NF1] [NF2] [NF3]"""
        self.exactly_n_args(line.split(), 3)
        args = line.split()
        isBadInput = False
        if args[0] not in nfs:
            print "%s not in nfs, please check avaiable nfs using \'list_nfs\'" % args[0]
            isBadInput = True
        if args[1] not in nfs:
            print "%s not in nfs, please check avaiable nfs using \'list_nfs\'" % args[1]
            isBadInput = True
        if args[2] not in nfs:
            print "%s not in nfs, please check avaiable nfs using \'list_nfs\'" % args[1]
            isBadInput = True
        if not isBadInput:
            if args[0] not in self.dag.graph:
                self.dag.add_node(args[0])
            if args[1] not in self.dag.graph:
                self.dag.add_node(args[1])
            if args[2] not in self.dag.graph:
                self.dag.add_node(args[2])
            self.dag.add_edge(args[0], args[1])
            self.dag.add_edge(args[0], args[2])

    def do_end_of_sfc(self, line):
        """End of SFC"""
        self.exactly_n_args(line.split(), 0)
        if not self.haveAssignedDir or self.targetDir == '':
            print "Please using assign_dir first to indicate work directory"
        else:
            # judge DAG structure
            if self.dag.validate()[0] is False:
                print "You have constructed a SFC with non-DAG structure, reject it"
            else:
                topoOrder, topoOrder_str = self.dag.topological_sort(), ""
                for item in topoOrder:
                    topoOrder_str += item
                    topoOrder_str += ","
                topoOrder_str = topoOrder_str[:-1]

                # create sfc request in terms of txt
                cmd = "echo \"%s\" >> %s/sfc%d.txt" % (topoOrder_str, self.targetDir, self.sfcNumber)
                status, output = commands.getstatusoutput(cmd)
                if status != 0:
                    print "Cannot create SFC request"
                    print output
                    return

            self.dag = DAG()
            self.sfcNumber += 1

    def do_greet(self, line):
        print "hello"

    def do_EOF(self, line):
        """Quits CLI."""
        print
        return SystemExit

    def do_exit(self, line):
        """Quits CLI."""
        print
        return SystemExit

    def do_quit(self, line):
        """Quits CLI."""
        print 
        return SystemExit

    def do_run(self, line):
        """The command used to convert the input requests to a P4 program"""
        self.exactly_n_args(line.split(), 0)
        if not self.haveAssignedDir:
            print "Please using assign_dir first to indicate work directory"
        else:
            # converter process
            cmd = "./converter.py -d %s" % self.targetDir
            status, output = commands.getstatusoutput(cmd)
            if status != 0:
                print "Error: converter processing error"
                print output
                return
            # generator process
            cmd = "./generator.py -f %s/result.txt" % self.targetDir
            status, output = commands.getstatusoutput(cmd)
            if status != 0:
                print "Error: generator processing error"
                print output
                return
            print "Successfully generating P4 program, see switch.p4 under the directory \"backend/\"."
            return SystemExit


if __name__ == '__main__':
    cmd = "./reset.sh"
    status, output = commands.getstatusoutput(cmd)
    prompt = p4scPrompt()
    prompt.cmdloop('Starting P4SC command line interface...')
