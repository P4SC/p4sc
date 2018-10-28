#include "includes/drop_reason_codes.h"
#include "includes/p4_table_sizes.h"
#include "includes/intrinsic.p4"
#include "includes/defines.h"
#include "includes/header.p4"
#include "includes/parser.p4"
#include "blocks/includes.p4"
#include "copy/includes.p4"

// 13 bits = 8192 state entries
#define STATE_MAP_SIZE 13
#define STATE_TABLE_SIZE 8192
#include "includes/openstate.p4"
// #include "blocks/fwd_consistency.p4"
#include "blocks/port_knocking.p4"

// update ipv4 checksum 

field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
        ipv4.totalLen;
        ipv4.identification;
        ipv4.flags;
        ipv4.fragOffset;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.srcAddr;
        ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}

// actions

action _drop() {
	drop();
}

action _nop() {
}

action nop() {
}

action on_miss() {
}

/**
 * for universal applications:
 * action ipv4_forward(macAddr, port) {
 *      modify_field(standard_metadata.egress_spec, port);
 *      modify_field(ethernet.srcAddr, ethernet.dstAddr);
 *      modify_field(ethernet.dstAddr, macAddr);
 *      modify_field(ipv4.ttl, ipv4.ttl-1);
 * }
 */

action rewrite_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
}

action broadcast() {
	modify_field(intrinsic_metadata.mcast_grp, 1);
}

table arp {
	actions {_nop; broadcast;}
}
