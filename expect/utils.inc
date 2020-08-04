#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Retrieve script parameters from environment variables. If they don't exist,
# return empty string
proc get_param {name {default ""}} {
	if {[info exists ::env($name)]} {
		return $::env($name)
	} else {
		return $default
	}
}

proc exit_uart {status} {
	# Allow UART output to flush
	sleep 1
	send "\x1b"
	send "close\r"
	exit $status
}

proc exit_timeout {} {
	# Allow UART output to flush
	sleep 1
	puts "<<TIMEOUT>>"
	exit_uart -1
}

# Expect a given string, and an optional message to be output when it's found.
# If not supplied, the message defaults to the string itself.
proc expect_string {the_string {the_message ""}} {
	if {$the_message eq ""} {
		set the_message $the_string
	}

	expect {
		$the_string {
			puts "<<$the_message>>"
		}
		timeout {
			puts "<<Not found: $the_string>>"
			exit_timeout
		}
	}
}

# Expect a given regular expression, and an optional message to be output when
# it's found. If not supplied, the message defaults to the regular expression
# itself.
proc expect_re {the_re {the_message ""}} {
	if {$the_message eq ""} {
		set the_message $the_re
	}

	expect {
		-re $the_re {
			puts "<<$the_message>>"
		}
		timeout {
			puts "<<Not found: $the_re>>"
			exit_timeout
		}
	}
}
