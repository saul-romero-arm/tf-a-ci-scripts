#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

/terminal_uart0/ { ports[0] = $NF }
/terminal_uart_ap/ { ports[1] = $NF }
/terminal_uart_aon/ { ports[2] = $NF }
END {
	for (i = 0; i < num_uarts; i++) {
		if (ports[i] != "")
			print "ports[" i "]=" ports[i]
	}
}
