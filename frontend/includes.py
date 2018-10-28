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
}

p4_eg_code_map = {
	'qos'          : 'process_egress_qos_map',
	'nat'          : 'process_egress_nat',
}

nfs = ['port_knocking', 'qos', 'ipsg', 'ipv4_forward', 'l2_forward',
       'nat', 'ecmp', 'meter_index', 'hashes', 'meter_action', 
       'basic_monitor', 'heavy_hitter']