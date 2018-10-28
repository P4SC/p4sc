action l2_forward(port) {
	modify_field(standard_metadata.egress_spec, port);
}

table l2_forward_t {
	reads {
		ethernet.dstAddr : exact;
	}
	actions {
		on_miss; l2_forward;
	}
}

control process_l2_forward {
	apply(l2_forward_t);
}