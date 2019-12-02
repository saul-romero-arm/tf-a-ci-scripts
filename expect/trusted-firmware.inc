#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#
# Script to interact with Trusted Firmware when resetting to BL1.
#
# This script is not standalone and should be sourced by a top expect script.
#

# Initial boot message won't be present if we're starting at BL31. Skip waiting
# for them by inspecting the environment variable 'skip_early_boot_msgs'
if {![info exists ::env(skip_early_boot_msgs)]} {
	expect_string "Booting Trusted Firmware"
	expect_string "BL1: Booting BL2"
	expect_re "BL1: Booting BL3-?1" "BL1: Booting BL31"
} else {
	puts "<<Skipping early boot messages from BL1 and BL2>>"
}
