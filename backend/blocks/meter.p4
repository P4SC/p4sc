/*
 * Meter processing
 */

/*
 *  color_RED    : 2
 *  color_Yellow : 1
 *  color_Green  : 0
 */

/*
 * Meter metadata
 */
header_type meter_metadata_t {
    fields {
        packet_color : 2;               /* packet color */
        meter_index : 16;               /* meter index */
    }
}
metadata meter_metadata_t meter_metadata;

/*****************************************************************************/
/* Meters                                                                    */
/*****************************************************************************/
#ifndef METER_DISABLE
action meter_deny() {
    drop();
}

action meter_permit() {
}

#ifndef STATS_DISABLE
counter meter_stats {
    type : packets;
    direct : meter_action;
}
#endif /* STATS_DISABLE */

table meter_action {
    reads {
        meter_metadata.packet_color : exact;
        meter_metadata.meter_index : exact;
    }

    actions {
        meter_permit;
        meter_deny;
    }
    size: METER_ACTION_TABLE_SIZE;
}

meter meter_index {
    type : bytes;
    direct : meter_index;
    result : meter_metadata.packet_color;
}

table meter_index {
    reads {
        meter_metadata.meter_index: exact;
    }
    actions {
        nop;
    }
    size: METER_INDEX_TABLE_SIZE;
}
#endif /* METER_DISABLE */

action set_meter_index_action(index) {
    modify_field(meter_metadata.meter_index, index);
}

// set meter index
table set_meter_index {
    reads {
        ipv4.dstAddr: lpm;
    }
    actions {
        nop;
        set_meter_index_action;
    }
}

control process_meter_index {
#ifndef METER_DISABLE
    // if (DO_LOOKUP(METER)) {
        apply(set_meter_index);
        apply(meter_index);
    // }
#endif /* METER_DISABLE */
}

control process_meter_action {
#ifndef METER_DISABLE
    // if (DO_LOOKUP(METER)) {
        apply(meter_action);
    // }
#endif /* METER_DISABLE */
}