#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# If we exit from a secondary uart, and if that had lots of prints, then the
# model will stall. See: https://jira.arm.com/browse/SDDKW-43675. So, we wait
# here expect for something that never arrives.

set timeout -1
puts "<<holding terminal>>"
expect {
	"FOOBAR" {
		exit_uart -1
	}
}
