// a simple implementation of TAYGA: a stateless NAT64 implementation for Linux

// metadatas

header_type ip426_info_t {
	fields {
		ipv4_ihl : 4;
		ipv4_ttl : 8;
		ipv4_totalLen : 16;
		ipv6_nextHdr : 8;
	}
}
metadata ip426_info_t ip426_info;

header_type ip624_info_t {
	fields {
		// how to convert the ipv6 payload into ipv4 ihl?
		ipv6_payloadLen : 16;
		ipv6_hopLimit : 8;
		ipv4_protocol : 8;
	}
}
metadata ip624_info_t ip624_info;

// major actions

action ip426_action(srcAddr, dstAddr) {
	// add information to ip426_info
	modify_field(ip426_info.ipv4_ihl, ipv4.ihl);
	modify_field(ip426_info.ipv4_ttl, ipv4.ttl);
	modify_field(ip426_info.ipv4_totalLen, ipv4.totalLen);

	remove_header(ipv4);
	add_header(ipv6);

	modify_field(ipv6.srcAddr, srcAddr);
	modify_field(ipv6.dstAddr, dstAddr);

	// update version type
	modify_field(ipv6.version, 6);

	// update payloadLen
	modify_field(ipv6.payloadLen, ip426_info.ipv4_totalLen);
	subtract_from_field(ipv6.payloadLen, ip426_info.ipv4_ihl);

	// update limit of hop
	modify_field(ipv6.hopLimit, ip426_info.ipv4_ttl); 

	// update the nextHdr
	modify_field(ipv6.nextHdr, ip426_info.ipv6_nextHdr);

	// modify ethernet type
	modify_field(ethernet.etherType, 0x86dd);
}

action ip624_action(srcAddr, dstAddr) {
	// add information to ip624_info
	modify_field(ip624_info.ipv6_payloadLen, ipv6.payloadLen);
	modify_field(ip624_info.ipv6_hopLimit, ipv6.hopLimit); 

	remove_header(ipv6);
	add_header(ipv4);

	modify_field(ipv4.srcAddr, srcAddr);
	modify_field(ipv4.dstAddr, dstAddr);

	// update version type
	modify_field(ipv4.version, 4);

	// update ihl
	modify_field(ipv4.ihl, 5);
	
	// update totalLen
	modify_field(ipv4.totalLen, ipv4.ihl);
	add_to_field(ipv4.totalLen, ip624_info.ipv6_payloadLen);

	// update ttl
	modify_field(ipv4.ttl, ip624_info.ipv6_hopLimit); 

	// update the nextHdr
	modify_field(ipv4.protocol, ip624_info.ipv4_protocol);	

	// update the ethernet type
	modify_field(ethernet.etherType, 0x0800);
}

// tables and actions for setting metadatas

action set_ip426_icmp() {
	modify_field(ip426_info.ipv6_nextHdr, 0x501);
}

table set_ip426_icmp_t {
	actions {
		set_ip426_icmp; nop;
	}
}

action set_ip426_tcp() {
        modify_field(ip426_info.ipv6_nextHdr, 0x506);
}

table set_ip426_tcp_t {
        actions {
                set_ip426_tcp; nop;
        }
}

action set_ip426_udp() {
        modify_field(ip426_info.ipv6_nextHdr, 0x511);
}

table set_ip426_udp_t {
        actions {
                set_ip426_udp; nop;
        }       
}

action set_ip624_icmp() {
        modify_field(ip624_info.ipv4_protocol, 58);
}

table set_ip624_icmp_t {
        actions {
                set_ip624_icmp; nop;
        }
}

action set_ip624_tcp() {
	modify_field(ip624_info.ipv4_protocol, 6);
}

table set_ip624_tcp_t {
	actions {
		set_ip624_tcp; nop;
	}
}

action set_ip624_udp() {
        modify_field(ip624_info.ipv4_protocol, 17);
}       

table set_ip624_udp_t {
        actions {
                set_ip624_udp; nop;
        }       
}

// TAYGA tables

table ip624 {
	reads {
		// for simplifying the problem, we don't use lpm here
		ipv6.srcAddr : exact; 
		ipv6.dstAddr : exact; 
	}
	actions {
		ip624_action; nop;
	}
}

table ip426 {
	reads {
		ipv4.srcAddr : exact;
		ipv4.dstAddr : exact;
	}
	actions {
		ip426_action; nop;
	}
}

// control flow

control process_tayga_nat64 {
	if (valid(ipv4)) {
		if (valid(tcp)) {
			apply(set_ip426_tcp_t);
		} else if (valid(icmp)) {
			apply(set_ip426_icmp_t);
		} else if (valid(udp)) {
			apply(set_ip426_udp_t);
		}
		apply(ip426);
	} else if (valid(ipv6)) {
		if (valid(tcp)) {
                        apply(set_ip624_tcp_t);
                } else if (valid(icmp)) {
                        apply(set_ip624_icmp_t);
                } else if (valid(udp)) {
                        apply(set_ip624_udp_t);
                }		
		apply(ip624);
	}
}
