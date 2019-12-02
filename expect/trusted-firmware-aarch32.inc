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

if {![info exists ::env(skip_early_boot_msgs)]} {
	expect_string "Booting Trusted Firmware"
	expect_string "BL1: Booting BL2"
	expect_string "BL1: Booting BL32"
	expect_string "SP_MIN:" "Booting SP_MIN"
} else {
	puts "<<Skipping early boot messages from BL1 and BL2>>"
}
