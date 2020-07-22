#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

/terminal_s0/ { ports[0] = $NF }
/terminal_s1/ { ports[1] = $NF }

# SCP uart window title
/terminal_uart_aon/ { uart_aon[$NF]++ }

END {
	# start with idx 2, port idx 0 and 1 are taken by s0 and s1
	uart_aon_idx = 2;
	for (port in uart_aon) {
		ports[uart_aon_idx++] = port;
	}

	for (i = 0; i < num_uarts; i++) {
		if (ports[i] != "")
			print "ports[" i "]=" ports[i]
	}
}
