action ipv4_forward(port) {
        modify_field(standard_metadata.egress_spec, port);
        modify_field(ipv4.ttl, ipv4.ttl-1);
}

// table used to implement l3 forwarding

table ipv4_forward_t {
        reads {
                ipv4.dstAddr : lpm;
        }
        actions {
                _nop; ipv4_forward;
        }
}

control process_ipv4_forward {
	apply(ipv4_forward_t);
}
