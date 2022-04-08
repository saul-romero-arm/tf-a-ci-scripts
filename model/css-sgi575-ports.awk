#
# Copyright (c) 2019-2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

/terminal_uart1_ap/ { ports[0] = $NF }
/terminal_uart_ap/ { ports[1] = $NF }
/terminal_uart_aon/ { ports[2] = $NF }
END {
	for (i = 0; i < num_uarts; i++) {
		if (ports[i] != "")
			print "ports[" i "]=" ports[i]
	}
}
