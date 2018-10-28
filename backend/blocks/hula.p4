// hula.p4 version 14: converting by Wasdns

header_type meta_tmp_t {
    fields {
        tmp        : 16;
        old_qdepth : qdepth_t;
        old_digest : digest_t; 
        flow_hash  : 16;
        port       : 16;
    }
}
metadata meta_tmp_t meta_tmp;

/* 
 * At destination ToR, saves the queue depth of the best path from
 * each source ToR
 */
register srcindex_qdepth_reg {
    width : qdepth_t;
    instance_count : TOR_NUM;
}

/* 
 * At destination ToR, saves the digest of the best path from
 * each source ToR
 */
register srcindex_digest_reg {
    width : digest_t;
    instance_count : TOR_NUM;
}

/* At each hop, saves the next hop to reach each destination ToR */
register dstindex_nhop_reg {
    width : 16;
    instance_count : TOR_NUM;
}

/* At each hop saves the next hop for each flow */
register flow_port_reg {
    width : 16;
    instance_count : 65536;
}

action update_ttl() {
    modify_field(ipv4.ttl, ipv4.ttl-1);
}

action set_dmac(dstAddr) {
    modify_field(ethernet.srcAddr, ethernet.dstAddr);
    modify_field(ethernet.dstAddr, dstAddr);
}

/* This action just applies source routing */
action srcRoute_nhop() {
    modify_field(standard_metadata.egress_spec, srcRoutes[0].port);
    pop(srcRoutes, 1);
}

/* 
 * Runs if it is the destination ToR.
 * Control plane Gives the index of register for best path from source ToR
 */
action hula_dst(index) {
    modify_field(hula_metadata.index, index);
}

/* 
 * In reverse path, update nexthop to a destination ToR to ingress port
 * where we receive hula packet
 */
action hula_set_nhop(index) {
    register_write(dstindex_nhop_reg, index, standard_metadata.ingress_port); 
}

/* Read next hop that is saved in hula_set_nhop action for data packets */
action hula_get_nhop(index) { 
    register_read(meta_tmp.tmp, dstindex_nhop_reg, index); 
    modify_field(standard_metadata.egress_spec, meta_tmp.tmp); 
}

/* Record best path at destination ToR */
action change_best_path_at_dst() {
    register_write(srcindex_qdepth_reg, hula_metadata.index, hula.qdepth); 
    register_write(srcindex_digest_reg, hula_metadata.index, hula.digest); 
}

/* 
 * At destination ToR, return packet to source by
 * - changing its hula direction
 * - send it to the port it came from
 */
action return_hula_to_src() {
    modify_field(hula.dir, 1);
    modify_field(standard_metadata.egress_spec, standard_metadata.ingress_port);
}

/* 
 * In forward path:
 * - if destination ToR: run hula_dst to set the index based on srcAddr
 * - otherwise run srcRoute_nhop to perform source routing
 */
table hula_fwd {
    reads {
        ipv4.dstAddr: exact;
        ipv4.srcAddr: exact;
    }
    actions {
        hula_dst;
        srcRoute_nhop;
    } 
    size : TOR_NUM_1; // TOR_NUM + 1
}

/* 
 * At each hop in reverse path
 * update next hop to destination ToR in registers.
 * index is set based on dstAddr
 */
table hula_bwd {
    reads {
        ipv4.dstAddr: lpm;
    }
    actions {
        hula_set_nhop;
    }
    size : TOR_NUM;
}

/* 
 * in reverse path: 
 * - if source ToR (srcAddr = this switch) drop hula packet 
 * - otherwise, just forward in the reverse path based on source routing
 */
table hula_src {
    reads {
        ipv4.srcAddr: exact;
    }
    actions {
        drop;
        srcRoute_nhop;
    } 
    size : 2;
}

/*
 * get nexthop based on dstAddr using registers
 */
table hula_nhop {
    reads {
        ipv4.dstAddr: lpm;
    }
    actions {
        hula_get_nhop;
        _drop;
    } 
    size : TOR_NUM;
}

// table used as default action

table change_best_path_at_dst_tb {
    actions { change_best_path_at_dst; }
}

table return_hula_to_src_tb {
    actions{ return_hula_to_src; }
}

table drop_tb {
    actions { _drop; }
}

field_list flow_hash_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    udp.srcPort;
}

field_list_calculation flow_hash_cal {
    input { 
        flow_hash_list;
    }
    algorithm : crc16;
    output_width : 16;
}

control process_hula_dst {
    /* if it is the destination ToR compare qdepth */
    register_read(meta_tmp.old_qdepth, srcindex_qdepth_reg, hula_metadata.index);
                    
    if (meta_tmp.old_qdepth > hula.qdepth) {
        apply(change_best_path_at_dst_tb);

        /* only return hula packets that update best path */
        apply(return_hula_to_src_tb);
    } else {

        /* update the best path even if it has gone worse 
         * so that other paths can replace it later
         */
        register_read(meta_tmp.old_digest, srcindex_digest_reg, hula_metadata.index);
        if (meta_tmp.old_digest == hula.digest) {
            register_write(srcindex_qdepth_reg, hula_metadata.index, hula.qdepth);
        }

        apply(drop_tb);
    }
}

control process_hula_ingress {
    if (valid(hula)) {
        if (hula.dir == 0) {
            apply(hula_fwd) {
                /* if hula_dst action ran, this is the destination ToR */
                hula_dst {
                    process_hula_dst();
                }
            }
        } else {
            /* update routing table in reverse path */
            apply(hula_bwd);
            /* drop if source ToR */
            apply(hula_src);
        }
    } else if (valid(ipv4)) {
        /* dest_field, base_number, field_list_name, size */
        modify_field_with_hash_based_offset(meta_tmp.flow_hash, 16w0, flow_hash_cal, 32w65536);

        /* look into hula tables */
        register_read(meta_tmp.port, flow_port_reg, meta_tmp.flow_hash); // bit problem

        if (meta_tmp.port == 0) {
            /* if it is a new flow check hula paths */
            apply(hula_nhop);
            register_write(flow_port_reg, meta_tmp.flow_hash, standard_metadata.egress_spec); // bit problem
        } else {
            /* old flows still use old path to avoid oscilation and packet reordering */
            modify_field(standard_metadata.egress_spec, meta_tmp.port);
        }

        /* set the right dmac so that ping and iperf work */
        apply(dmac);
    } else {
        apply(drop_tb);
    }
}

action update_queue_length() {
    modify_field(hula.qdepth, queueing_metadata.deq_qdepth);
}

table update_queue_length_tb {
    actions { update_queue_length; }
}

control process_hula_egress {
    if (valid(hula) and hula.dir == 0) {
        /* pick max qdepth in hula forward path */
        if (hula.qdepth < queueing_metadata.deq_qdepth) {
            /* update queue length */
            apply(update_queue_length_tb);
        }
    }
} 
