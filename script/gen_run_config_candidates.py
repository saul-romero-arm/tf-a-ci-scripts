#!/usr/bin/env python3
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Output to stdout the chosen run configuration fragments for a given run
# configuration. With -p, the script prints all fragments considered without
# validating whether it exists.

import argparse
import os
import sys

parser = argparse.ArgumentParser(description="Choose run configurations")
parser.add_argument("--print-only", "-p", action="store_true", default=False,
        help="Print only; don't check for matching run configs.")
parser.add_argument("args", nargs=argparse.REMAINDER, help="Run configuration")
opts = parser.parse_args()

if len(opts.args) != 1:
    raise Exception("Exactly one argument expected")

exit_code = 0

# Obtain path to run_config directory
script_root = os.path.dirname(os.path.abspath(sys.argv[0]))
run_config_dir = os.path.join(script_root, os.pardir, "run_config")

arg = opts.args[0]
run_config = arg.split(":")[-1]
if not run_config:
    raise Exception("Couldn't extract run config from " + arg)

if run_config == "nil":
    sys.exit(exit_code)

fragments = run_config.split("-")

ignored_fragments      = ['bmcov']
not_prefixed_fragments = ['debug']

for f in fragments[1:]:
    if f in ignored_fragments:
        # these fragments are ignored
        continue
    elif f in not_prefixed_fragments:
        # these fragments are NOT prefixed by first fragment
        fragment = f
    else:
        # for the rest of the cases, prefix first fragment
        fragment = "-".join([fragments[0],f])

    if opts.print_only:
        print(fragment)
    else:
        # Output only if a matching run config exists
        if os.path.isfile(os.path.join(run_config_dir, fragment)):
            # Stop looking for generic once a specific fragment is found
            print(fragment)
        else:
            print("warning: {}: no matches for fragment '{}'".format(
                arg, fragment), file=sys.stderr)
            exit_code = 1

sys.exit(exit_code)
