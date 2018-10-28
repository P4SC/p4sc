// basic_monitor.p4, based on OpenNetVM examples

header_type pkt_id_t {
	fields {
		id : 32;
		next_id : 32;
	}
}
metadata pkt_id_t pkt_id;

register set_pkt_id_reg {
	width : 32;
	instance_count : 1;
}

action read_id_from_reg() {
	// read id from register
	register_read(pkt_id.id, set_pkt_id_reg, 0);
	// plus the register value
	modify_field(pkt_id.next_id, pkt_id.id);
	add_to_field(pkt_id.next_id, 1);
	register_write(set_pkt_id_reg, 0, pkt_id.next_id);
}

action send_to_monitor(port) {
	// TODO: write ingress port to packet field
	// write 0 to the register
	register_write(set_pkt_id_reg, 0, 0);
	modify_field(standard_metadata.egress_spec, port);
}

table set_pkt_id {
	actions {
		on_miss; read_id_from_reg;
	}
}

table basic_monitor {
	reads {
		pkt_id.id : exact;
	}
	actions {
		on_miss; send_to_monitor;
	}
}

control process_basic_monitor {
	apply(set_pkt_id);
	apply(basic_monitor);
}