/*********************************
 FuZhou University, SDNLab
 Added by Chen, 2017.8
 *********************************/

/* Copyright 2017 FuZhou University SDNLab, Edu. 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
   http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

/*********************************
    template: header.p4
 *********************************/

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type srcRoute_t {
    fields {
        bos  : 1;
        port : 15;
    }
}

header_type hula_t {
    fields {
        /* 0 is forward path, 1 is the backward path */
        dir    : 1;
        /* max qdepth seen so far in the forward path */
        qdepth : qdepth_t;
        /* digest of the source routing list to uniquely identify each path */
        digest : digest_t;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}
