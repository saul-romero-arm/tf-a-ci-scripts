#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#!/usr/bin/env awk
#
# This is a script to categorize tests within this repo by type. This script is
# intended to be run with the output of `find group -type f`, run from within
# the root directory of this repo piped into it. See the bash script with the
# same name for an usage example.

BEGIN {
	# We're breaking records upon the "/" character so that we can have an
	# aggregation that's keyed by test group, if we want to.
	FS = "/";
}

# Here we filter out any records without exactly 3 fields (i.e. 3-level paths)
# and categorize the rest.
NF == 3 {
	if (/-l1/) category = "\"l1 - Every Patch\"";
	else if (/-l2/) category = "\"l2 - Risky or Big Patches\"";
	else if (/-l3/) category = "\"l3 - Daily\"";
	else if (/-manual/ || /-release/ ) category = "\"remainder - Every Release\"";
	else if (/-unstable/) category = "\"unstable - Never Run\"";
	else category = "\"remainder - Every Release\"";
	cats[category] = 1
	# Each of these categorizes a test into a category, based on a regular
	# expression. When you add another test category, you should also add
	# printing to the print group loop below.
	if (/linux/ || /uboot/ || /edk2/ || /:fvp-([a-z0-9.]-)*spm/ || /:juno-([a-z0-9.]-)*scmi/) integration[category] += 1;
	else if (/tftf/) component[category] += 1;
	else if (/coverity/ || /misra/ || /scan_build/) static[category] += 1;
	else if (/:nil/ || /norun/) build[category] += 1;
	else print $0 " No test category; excluding from data" >> "/dev/stderr";
}


END {
	for (name in cats)
		# This prints a single test group, by name. When you add another
		# category (with another map), add another field to this print.
		printf("%s %d %d %d %d\n",
			name,
			build[name],
			static[name],
			component[name],
			integration[name]);
}
