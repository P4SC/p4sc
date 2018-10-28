/*
Copyright 2013-present Barefoot Networks, Inc. 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/*
 * Security related processing - Storm control, IPSG, etc.
 */

/*
 * security metadata
 */
header_type security_metadata_t {
    fields {
        ipsg_enabled : 1;                      /* is ip source guard feature enabled */
        ipsg_check_fail : 1;                   /* ipsg check failed */
    }
}

metadata security_metadata_t security_metadata;

#ifndef IPSG_DISABLE
/*****************************************************************************/
/* IP Source Guard                                                           */
/*****************************************************************************/
action ipsg_miss() {
    modify_field(security_metadata.ipsg_check_fail, TRUE);
}

table ipsg_permit_special {
    reads {
        l3_metadata.lkp_ip_proto : ternary;
        l3_metadata.lkp_l4_dport : ternary;
        ipv4_metadata.lkp_ipv4_da : ternary;
    }
    actions {
        ipsg_miss;
    }
    size : IPSG_PERMIT_SPECIAL_TABLE_SIZE;
}

table ipsg {
    reads {
        // ingress_metadata.ifindex : exact;
        // ingress_metadata.bd : exact;
        l2_metadata.lkp_mac_sa : exact;
        ipv4_metadata.lkp_ipv4_sa : exact;
    }
    actions {
        on_miss; nop; _drop;
    }
    size : IPSG_TABLE_SIZE;
}
#endif /* IPSG_DISABLE */


/* duplicate table for ipsg */
table ipsg_firewall_t {
    reads {
        ethernet.srcAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        nop; _drop;
    }
}

control process_ip_sourceguard {
#ifndef IPSG_DISABLE
    /* l2 security features */
    /* if ((ingress_metadata.port_type == PORT_TYPE_NORMAL) and
        (security_metadata.ipsg_enabled == TRUE)) {
        apply(ipsg) {
            on_miss {
                apply(ipsg_permit_special);
            }
        }*/

        apply(ipsg_firewall_t);
    // }
#endif /* IPSG_DISABLE */
}
