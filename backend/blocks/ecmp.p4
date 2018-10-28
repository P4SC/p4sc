header_type routing_metadata_t {
    fields {
        nhop_ipv4 : 32;
        // TODO: if you need extra metadata for ECMP, define it here
    }
}

metadata routing_metadata_t routing_metadata;

action set_nhop(nhop_ipv4, port) {
    modify_field(routing_metadata.nhop_ipv4, nhop_ipv4);
    modify_field(standard_metadata.egress_spec, port);
    add_to_field(ipv4.ttl, -1);
}

// SOLUTION --->

// We replace the ipv4_lpm table by the ecmp_group table. This new table uses an
// action profile with a selector. Each match entry can be associated with a
// "group", each group can contain an arbitrary number of members and the
// selector ensures that in case of match a random member of the group is
// selected. Each member corresponds to an action + action data.

#define ECMP_BIT_WIDTH 10
#define ECMP_GROUP_TABLE_SIZE 1024
#define ECMP_SELECT_TABLE_SIZE 16384

field_list l3_hash_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}

field_list_calculation ecmp_hash {
    input {
        l3_hash_fields;
    }
    algorithm : crc16;
    output_width : ECMP_BIT_WIDTH;
}

table ecmp_group {
    reads {
        ipv4.dstAddr : lpm;
    }
    action_profile: ecmp_action_profile;
    size : ECMP_GROUP_TABLE_SIZE;
}

action_selector ecmp_selector {
    selection_key : ecmp_hash;
}

action_profile ecmp_action_profile {
    actions {
        _drop;
        set_nhop;
    }
    size : ECMP_SELECT_TABLE_SIZE;
    dynamic_action_selection : ecmp_selector;
}

// <--- SOLUTION

control process_ecmp {
    if(valid(ipv4) and ipv4.ttl > 0 and valid(tcp)) {
        // TODO: implement ECMP here
        // SOLUTION --->
        // ipv4_lpm replaced by our new ecmp_group table
        apply(ecmp_group);
        // <--- SOLUTION
    }
}


