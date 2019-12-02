#!/usr/bin/env python3
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

"""
Check if a given file includes the copyright boiler plate.
This checker supports the following comment styles:
    * Used by .c, .h, .S, .dts and .dtsi files
    # Used by Makefile (including .mk)
"""

import argparse
import datetime
import collections
import fnmatch
import shlex
import os
import re
import sys
import utils
from itertools import islice

# File extensions to check
VALID_FILE_EXTENSIONS = ('.c', '.S', '.h', 'Makefile', '.mk', '.dts', '.dtsi', '.ld')

# Paths inside the tree to ignore. Hidden folders and files are always ignored.
# They mustn't end in '/'.
IGNORED_FOLDERS = (
    'include/lib/libfdt',
    'lib/compiler-rt',
    'lib/libfdt',
    'lib/zlib'
)

# List of ignored files in folders that aren't ignored
IGNORED_FILES = (
    'include/tools_share/uuid.h'
)

# Supported comment styles (Python regex)
COMMENT_PATTERN = '^(( \* ?)|(\# ?))'

# License pattern to match
LICENSE_PATTERN = '''(?P<copyright_prologue>
{0}Copyright \(c\) (?P<years>[0-9]{{4}}(-[0-9]{{4}})?), (Arm Limited|ARM Limited and Contributors)\. All rights reserved\.$
{0}$
{0}SPDX-License-Identifier: BSD-3-Clause$
)'''.format(
    COMMENT_PATTERN
)

# Compiled license pattern
RE_PATTERN = re.compile(LICENSE_PATTERN, re.MULTILINE)

COPYRIGHT_OK = 0
COPYRIGHT_ERROR = 1
COPYRIGHT_WARNING = 2

def check_copyright(path):
    '''Checks a file for a correct copyright header.'''

    with open(path) as file_:
        file_content = file_.read()

    if RE_PATTERN.search(file_content):
        return COPYRIGHT_OK

    for line in file_content.split('\n'):
        if 'SPDX-License-Identifier' in line:
            if ('BSD-3-Clause' in line or
                'BSD-2-Clause-FreeBSD' in line):
                return COPYRIGHT_WARNING
            break

    return COPYRIGHT_ERROR


def main(args):
    print("Checking the copyrights in the code...")

    all_files_correct = True

    if args.patch:
        print("Checking files modified between patches " + args.from_ref
              + " and " + args.to_ref + "...")

        (rc, stdout, stderr) = utils.shell_command(['git', 'diff',
            '--diff-filter=ACMRT', '--name-only', args.from_ref, args.to_ref ])
        if rc:
            return 1

        files = stdout.splitlines()

    else:
        print("Checking all files tracked by git...")

        (rc, stdout, stderr) = utils.shell_command([ 'git', 'ls-files' ])
        if rc:
            return 1

        files = stdout.splitlines()

    count_ok = 0
    count_warning = 0
    count_error = 0

    for f in files:

        if utils.file_is_ignored(f, VALID_FILE_EXTENSIONS, IGNORED_FILES, IGNORED_FOLDERS):
            if args.verbose:
                print("Ignoring file " + f)
            continue

        if args.verbose:
            print("Checking file " + f)

        rc = check_copyright(f)

        if rc == COPYRIGHT_OK:
            count_ok += 1
        elif rc == COPYRIGHT_WARNING:
            count_warning += 1
            print("WARNING: " + f)
        elif rc == COPYRIGHT_ERROR:
            count_error += 1
            print("ERROR: " + f)

    print("\nSummary:")
    print("\t{} files analyzed".format(count_ok + count_warning + count_error))

    if count_warning == 0 and count_error == 0:
        print("\tNo errors found")
        return 0

    if count_error > 0:
        print("\t{} errors found".format(count_error))

    if count_warning > 0:
        print("\t{} warnings found".format(count_warning))


def parse_cmd_line(argv, prog_name):
    parser = argparse.ArgumentParser(
        prog=prog_name,
        formatter_class=argparse.RawTextHelpFormatter,
        description="Check copyright of all files of codebase",
        epilog="""
For each source file in the tree, checks that the copyright header
has the correct format.
""")

    parser.add_argument("--tree", "-t",
                        help="Path to the source tree to check (default: %(default)s)",
                        default=os.curdir)

    parser.add_argument("--verbose", "-v",
                        help="Increase verbosity to the source tree to check (default: %(default)s)",
                        action='store_true', default=False)

    parser.add_argument("--patch", "-p",
                        help="""
Patch mode.
Instead of checking all files in the source tree, the script will consider
only files that are modified by the latest patch(es).""",
                        action="store_true")
    parser.add_argument("--from-ref",
                        help="Base commit in patch mode (default: %(default)s)",
                        default="master")
    parser.add_argument("--to-ref",
                        help="Final commit in patch mode (default: %(default)s)",
                        default="HEAD")

    args = parser.parse_args(argv)
    return args


if __name__ == "__main__":
    args = parse_cmd_line(sys.argv[1:], sys.argv[0])

    os.chdir(args.tree)

    rc = main(args)

    sys.exit(rc)
