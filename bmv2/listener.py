#!/usr/bin/env python
import sys
import struct
import argparse
import commands

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet, IPOption
from scapy.all import IP, TCP, ICMP, UDP, Raw 

parser = argparse.ArgumentParser(description='P4 Controller')
parser.add_argument('-p', '--port', help='listen port', 
                    type=str, action="store", default='s1-eth3')
parser.add_argument('-s', '--switch-name', help='switch name',
                    type=str, action="store", default='s1')
args = parser.parse_args()

_THRIFT_BASE_PORT = 22222

counter = 0

def handle_tcp_pkt(packet, thrift_port):
    global counter
    counter = counter+1
    return 'TCP Packet #{}: {} ==> {}, sport {} ==> dport {}'.format(counter, packet[0][1].src, packet[0][1].dst, packet[TCP].sport, packet[TCP].dport)

def main():
    # Get Thrift Port
    sw_name = args.switch_name
    index = int(sw_name[1:])-1
    thrift_port = _THRIFT_BASE_PORT+index

    iface = args.port
    print "sniffing on %s" % iface
    sys.stdout.flush()
    sniff(filter="tcp", iface = iface, prn = lambda x: handle_tcp_pkt(x, thrift_port))

if __name__ == '__main__':
    main()
