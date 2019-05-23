# P4SC: A High Performance and Flexible Framework for Service Function Chain

This repository maintains the source codes of P4SC (i.e., P4 Service Chaining), a system that provides high-performance Service Function Chain (SFC for simplicity) implementation on the P4-capable switch. P4SC provides high-level primitives for users to write SFC construction requests. The converter of P4SC converts the input SFC requests to the corresponding P4 program, while observing the P4 grammar and minimizing the number of duplicate P4 tables. Moreover, the runtime manager of P4SC provides convenient runtime management of SFC. Our experiments validates the capability of P4SC on various P4-capable devices, including the BMv2, NetFPGA-SUME, and Tofino. 

Note that due to the non-disclosure agreement, we only release partial but important parts of P4SC source codes in this repository. Specifically, this repository contains (1) complete source codes of converter, (2) partial source codes of generator used to generate P4 programs for BMv2, and (3) a Thrift-based script for managing SFCs at runtime. These source codes are enough to be used to implement SFCs atop BMv2. If you want more information about P4SC, please contact me via email: chenxiang2019@ict.ac.cn

## How to install P4SC?

1.Using the scripts of [p4Installer](https://github.com/Wasdns/p4Installer) to install BMv2 and p4c-bm.

2.Install py-dag:

```
git clone https://github.com/thieman/py-dag.git
cd py-dag/
python setup.py install
```

3.Install dependencies:

```
pip install -r requirements.txt
```

## How to run P4SC?

### Quick start

1.Execute `p4sc_CLI.py` and log into the command line:

```
./p4sc_CLI.py
```

2.Input your SFC requests. For example, we create two input requests (under the `examples/` folder):

```
// create the first input request
branch port_knocking qos ipsg
assign_dir test
end_of_sfc

// create the second input request
assign_dir test
before nat ecmp
before ecmp hashes
before ipsg qos
before qos nat
before l2_forward nat
end_of_sfc

// generate the P4 program 
run
```

3.Check your P4 program under the `backend/` folder.

4.[Option] Run `reset.sh` for cleaning up the environment:

```
./reset.sh
```

### Detailed steps

1.Using `p4sc_CLI.py` to construct SFC requests:

```
./p4sc_CLI.py

p4scCmd> help
```

We provide two example requests in `examples/` to illustrate how it works.

2.Using `converter.py` to build mid-end SFC file:

Assume that the `p4sc_CLI.py` produces the requests in `test/`. Now we use `converter.py` to merge these requests in `test/`

```
./converter.py -d test/
```

This command will produce `result.txt` which merges all SFC features described in user requests.

3.Using `generator.py` to produce output P4 program:

The input of generator is mid-end SFC file (e.g., `result.txt`).

```
./generator -f test/result.txt
```

And the output P4 program is produced in `backend/switch.p4`. 

## Integrating NFs into P4SC

To achieve this target, you should accomplish following steps:

1.Write your own P4 program that realizes dedicated NF and place it in `backend/blocks`;

e.g., I have wrote a P4 program named `skeleton.p4`. This program is composed of following codes:

```p4
// Action definitions
action nop() {}
action _drop() {
    drop();
}
action set_nhop(port) {
    modify_field(standard_metadata.egress_spec, port);
}

// Table definition
table skeleton_t {
    reads {
        ipv4.dstAddr: lpm;
    }
    actions {
        nop; _drop; set_nhop;
    }
}

// Control flow definition
// this control flow is invoked in ingress pipeline
control skeleton_ctrl { 
    if (valid(ipv4)) {
        apply(skeletion_t);
    }
}
```

2.Invoke your P4 code in [backend/blocks/includes.p4](../backend/blocks/includes.p4).

e.g., I add this "include" statement to includes.p4:

```p4
#include "hash.p4"
#include "ipsg.p4"
#include "nat.p4"
#include "ecmp.p4"
#include "meter.p4"
#include "qos.p4"
#include "basic_monitor.p4"
#include "heavy_hitter.p4"
#include "ipv4_forward.p4"
#include "l2_forward.p4"
#include "tayga.p4"
// I invoke my block here:
#include "skeleton.p4"
```

3.Give your NF with a beautiful name, e.g., `Skeleton`, and declare it on [frontend/includes.py](../frontend/includes.py).

e.g., Regarding my block `Skeleton`, I modify the `frontend/includes.py` as follows:

```python
#!/usr/bin/env python

p4_ing_code_map = {
	'port_knocking': 'process_port_knocking',
	'qos'          : 'process_ingress_qos_map',
	'ipsg'         : 'process_ip_sourceguard',
	'ipv4_forward' : 'process_ipv4_forward',
	'l2_forward'   : 'process_l2_forward',
	'nat'          : 'process_ingress_nat',
	'ecmp'         : 'process_ecmp',
	'meter_index'  : 'process_meter_index',
	'hashes'       : 'process_hashes',
	'meter_action' : 'process_meter_action',
	'basic_monitor': 'process_basic_monitor',
	'heavy_hitter' : 'process_heavy_hitter',
	# I add the control flow code of my new block here:
	'Skeleton'     : 'skeleton_ctrl'
}

p4_eg_code_map = {
	'qos'          : 'process_egress_qos_map',
	'nat'          : 'process_egress_nat',
}

nfs = ['port_knocking', 'qos', 'ipsg', 'ipv4_forward', 'l2_forward',
       'nat', 'ecmp', 'meter_index', 'hashes', 'meter_action', 
       'basic_monitor', 'heavy_hitter', 'Skeleton'] # and also append my block name to nfs
```

Congratulations! You have done this work. Now you can use your `Skeleton` to compose a SFC and generate P4 program.
