
/*****************************************************************************/
/* Qos Processing                                                            */
/*****************************************************************************/

header_type qos_metadata_t {
    fields {
        ingress_qos_group: 5;
        tc_qos_group: 5;       // traffic class qos group
        egress_qos_group: 5;
        lkp_tc: 8;             // lookup traffic class 
        trust_dscp: 1;         // Differentiated Services Code Point
        trust_pcp: 1;          // VLAN 802.1Q, Priority Code Point
    }
}

metadata qos_metadata_t qos_metadata;

/*****************************************************************************/
/* Ingress QOS Map                                                           */
/*****************************************************************************/
#ifndef QOS_DISABLE
action set_ingress_tc_and_color(tc, color) {
    modify_field(qos_metadata.lkp_tc, tc);
    modify_field(meter_metadata.packet_color, color);
}

action set_ingress_tc(tc) {
    modify_field(qos_metadata.lkp_tc, tc);
}

action set_ingress_color(color) {
    modify_field(meter_metadata.packet_color, color);
}

table ingress_qos_map_dscp {
    reads {
        qos_metadata.ingress_qos_group: ternary;
        l3_metadata.lkp_dscp: ternary;
    }

    actions {
        nop;
        set_ingress_tc;
        set_ingress_color;
        set_ingress_tc_and_color;
    }

    size: DSCP_TO_TC_AND_COLOR_TABLE_SIZE;
}

table ingress_qos_map_pcp {
    reads {
        qos_metadata.ingress_qos_group: ternary;
        l2_metadata.lkp_pcp: ternary;
    }

    actions {
        nop;
        set_ingress_tc;
        set_ingress_color;
        set_ingress_tc_and_color;
    }

    size: PCP_TO_TC_AND_COLOR_TABLE_SIZE;
}

#endif /* QOS_DISABLE */

// mark the traffic with the traffic class and packet color
control process_ingress_qos_map {
#ifndef QOS_DISABLE
    //if (DO_LOOKUP(QOS)) { // defined in define.h
        if (qos_metadata.trust_dscp == TRUE) {
            apply(ingress_qos_map_dscp);
        } else {
            if (qos_metadata.trust_pcp == TRUE) { // for VLAN 802.1Q
                apply(ingress_qos_map_pcp);
            }
        }
    //}
#endif /* QOS_DISABLE */
}


/*****************************************************************************/
/* Queuing                                                                   */
/*****************************************************************************/

#ifndef QOS_DISABLE
action set_icos(icos) { // Class of Service, CoS
    modify_field(intrinsic_metadata.ingress_cos, icos); 
}

action set_queue(qid) { // queue id
    modify_field(intrinsic_metadata.qid, qid); 
}

action set_icos_and_queue(icos, qid) {
    modify_field(intrinsic_metadata.ingress_cos, icos); 
    modify_field(intrinsic_metadata.qid, qid); 
}

table traffic_class {
    reads {
        qos_metadata.tc_qos_group: ternary;
        qos_metadata.lkp_tc: ternary;
    }

    actions {
        nop;
        set_icos;
        set_queue;
        set_icos_and_queue;
    }
    size: QUEUE_TABLE_SIZE;
}
#endif /* QOS_DISABLE */

control process_traffic_class { // for IPv6 Traffic Class
#ifndef QOS_DISABLE
    apply(traffic_class);
#endif /* QOS_DISABLE */
}

/*****************************************************************************/
/* Egress QOS Map                                                            */
/*****************************************************************************/
#ifndef QOS_DISABLE
action set_mpls_exp_marking(exp) {
    modify_field(l3_metadata.lkp_dscp, exp);
}

action set_ip_dscp_marking(dscp) {
    modify_field(l3_metadata.lkp_dscp, dscp);
}

action set_vlan_pcp_marking(pcp) {
    modify_field(l2_metadata.lkp_pcp, pcp);
}

table egress_qos_map {
    reads {
        qos_metadata.egress_qos_group: ternary;
        qos_metadata.lkp_tc: ternary;
        //meter_metadata.packet_color : ternary;
    }
    actions {
        nop;
        set_mpls_exp_marking;
        set_ip_dscp_marking;
        set_vlan_pcp_marking;
    }
    size: EGRESS_QOS_MAP_TABLE_SIZE;
}
#endif /* QOS_DISABLE */

control process_egress_qos_map {
#ifndef QOS_DISABLE
    // if (DO_LOOKUP(QOS)) {
        apply(egress_qos_map);
    // }
#endif /* QOS_DISABLE */
}