#!/usr/bin/env python

import argparse
import sys
import socket
import random
import struct

from scapy.all import *
from time import sleep

parser = argparse.ArgumentParser(description='Generating flows')
parser.add_argument('--dl-src', help='Data Link source address', 
                    type=str, action="store", default='00:00:00:00:00:01')
parser.add_argument('--dl-dst', help='Data Link destination address',
                    type=str, action="store", default='00:00:00:00:00:02')
parser.add_argument('--nw-src', help='Network source address',
                    type=str, action="store", default='10.0.0.1')
parser.add_argument('--nw-dst', help='Network destination address',
                    type=str, action="store", default='10.0.0.2')
parser.add_argument('--nw-proto', help='Network Layer protocol',
                    type=int, action="store", default=6)
parser.add_argument('--srcPort', help='L4 Source port',
                    type=int, action="store", default=520)
parser.add_argument('--dstPort', help='L4 Destination port',
                    type=int, action="store", default=520)
parser.add_argument('-n', '--num', help='total number', 
                    type=int, action="store", default=100)
parser.add_argument('-i', '--iface', help='Interface', 
                    type=str, action="store", default='s1-eth1')
parser.add_argument('-t', '--interval', help='Time interval between two packets', 
                    type=float, action="store", default=0.1)
args = parser.parse_args()

def TCPPacket(dl_src, dl_dst, nw_src, nw_dst, nw_proto, srcPort, dstPort, seqNum):
    return Ether(src=dl_src, dst=dl_dst) / IP(src=nw_src, dst=nw_dst) / TCP(sport=srcPort, dport=dstPort, seq=seqNum) 

def UDPPacket(dl_src, dl_dst, nw_src, nw_dst, nw_proto, srcPort, dstPort):
    return Ether(src=dl_src, dst=dl_dst) / IP(src=nw_src, dst=nw_dst) / UDP(sport=srcPort, dport=dstPort) 

def main():
    dl_src, dl_dst = args.dl_src, args.dl_dst
    nw_src, nw_dst = args.nw_src, args.nw_dst
    nw_proto = args.nw_proto
    srcPort, dstPort = args.srcPort, args.dstPort
    num, iface = args.num, args.iface
    t = args.interval

    for i in range(num):
        if nw_proto == 6:
            pkt = TCPPacket(dl_src, dl_dst, nw_src, nw_dst, nw_proto, srcPort, dstPort, i)
        elif nw_proto == 17:
            pkt = UDPPacket(dl_src, dl_dst, nw_src, nw_dst, nw_proto, srcPort, dstPort)
        else:
            print "\nThis script is not suuport this kind of protocol currently!\n"
            break
        
        sendp(pkt, iface=iface, verbose=0)
        sleep(t)

if __name__ == '__main__':
    main()