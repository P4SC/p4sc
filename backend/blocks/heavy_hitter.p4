/* Copyright 2013-present Barefoot Networks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// heavy_hitter.p4: SIGCOMM 2016 Demo 

// TODO: Define the threshold value
#define HEAVY_HITTER_THRESHOLD 100

header_type custom_metadata_t {
    fields {
        nhop_ipv4: 32;    // ipv4 address for next hop
        hash_val1: 16;    // calculated hash value based on csum16
        hash_val2: 16;    // calculated hash value based on crc16
        count_val1: 16;   // value read from heavy_hitter_hash1[hash_val1]
        count_val2: 16;   // value read from heavy_hitter_hash2[hash_val2]
    }
}

metadata custom_metadata_t custom_metadata;

// TODO: Define the field list to compute the hash on
// Use the 5 tuple of 
// (src ip, dst ip, src port, dst port, ip protocol)

field_list hash_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}

// TODO: Define two different hash functions to store the counts
// Please use csum16 and crc16 for the hash functions
field_list_calculation heavy_hitter_hash1 {
    input { 
        hash_fields;
    }
    algorithm : csum16;
    output_width : 16;
}

field_list_calculation heavy_hitter_hash2 {
    input { 
        hash_fields;
    }
    algorithm : crc16;
    output_width : 16;
}

// TODO: Define the registers to store the counts
register heavy_hitter_counter1{
    width : 16;
    instance_count : 16;
}

register heavy_hitter_counter2{
    width : 16;
    instance_count : 16;
}

// TODO: Actions to set heavy hitter filter
action set_heavy_hitter_count() {
    // modify_field_with_hash_based_offset paras:
    // dest_field, base_number, field_list_name, size.
    // result as a index by calculating (base + (hash_value%size)).
    modify_field_with_hash_based_offset(custom_metadata.hash_val1, 0,
                                        heavy_hitter_hash1, 16);
    register_read(custom_metadata.count_val1, heavy_hitter_counter1, custom_metadata.hash_val1);
    add_to_field(custom_metadata.count_val1, 1);
    register_write(heavy_hitter_counter1, custom_metadata.hash_val1, custom_metadata.count_val1);

    modify_field_with_hash_based_offset(custom_metadata.hash_val2, 0,
                                        heavy_hitter_hash2, 16);
    register_read(custom_metadata.count_val2, heavy_hitter_counter2, custom_metadata.hash_val2);
    add_to_field(custom_metadata.count_val2, 1);
    register_write(heavy_hitter_counter2, custom_metadata.hash_val2, custom_metadata.count_val2);
}

// TODO: Define the tables to run actions
table set_heavy_hitter_count_table {
    actions {
        set_heavy_hitter_count;
    }
    size: 1;
}

// TODO: Define table to drop the heavy hitter traffic
table drop_heavy_hitter_table {
    actions { _drop; }
    size: 1;
}

control process_heavy_hitter {
    // TODO: Add table control here
    apply(set_heavy_hitter_count_table);
    if (custom_metadata.count_val1 > HEAVY_HITTER_THRESHOLD and custom_metadata.count_val2 > HEAVY_HITTER_THRESHOLD) {
        apply(drop_heavy_hitter_table);
    }
}
