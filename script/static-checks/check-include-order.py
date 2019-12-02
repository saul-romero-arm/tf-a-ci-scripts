#!/usr/bin/env python3
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import argparse
import codecs
import os
import re
import sys
import utils


# File extensions to check
VALID_FILE_EXTENSIONS = ('.c', '.S', '.h')


# Paths inside the tree to ignore. Hidden folders and files are always ignored.
# They mustn't end in '/'.
IGNORED_FOLDERS = ("include/lib/stdlib",
                   "include/lib/libc",
                   "include/lib/libfdt",
                   "lib/libfdt",
                   "lib/libc",
                   "lib/stdlib")

# List of ignored files in folders that aren't ignored
IGNORED_FILES = (
)

def line_remove_comments(line):
    '''Remove C comments within a line. This code doesn't know if the line is
    commented in a multi line comment that involves more lines than itself.'''

    # Multi line comments
    while line.find("/*") != -1:
        start_comment = line.find("/*")
        end_comment = line.find("*/")
        if end_comment != -1:
            end_comment = end_comment + 2 # Skip the "*/"
            line = line[ : start_comment ] + line[ end_comment : ]
        else: # The comment doesn't end this line.
            line = line[ : start_comment ]

    # Single line comments
    comment = line.find("//")
    if comment != -1:
        line = line[ : comment ]

    return line


def line_get_include_path(line):
    '''It takes a line of code with an include directive and returns the file
    path with < or the first " included to tell them apart.'''
    if line.find('<') != -1:
        if line.find('.h>') == -1:
            return None
        inc = line[ line.find('<') : line.find('.h>') ]
    elif line.find('"') != -1:
        if line.find('.h"') == -1:
            return None
        inc = line[ line.find('"') : line.find('.h"') ]
    else:
        inc = None

    return inc


def file_get_include_list(path, _encoding='ascii'):
    '''Reads all lines from a file and returns a list of include paths. It
    tries to read the file in ASCII mode and UTF-8 if it fails. If it succeeds
    it will return a list of include paths. If it fails it will return None.'''

    inc_list = []

    try:
        f = codecs.open(path, encoding=_encoding)
    except:
        print("ERROR:" + path + ":open() error!")
        utils.print_exception_info()
        return None

    # Allow spaces in between, but not comments.
    pattern = re.compile(r"^\s*#\s*include\s\s*[\"<]")

    fatal_error = False

    try:
         for line in f:
            if pattern.match(line):
                line_remove_comments(line)
                inc = line_get_include_path(line)
                if inc != None:
                    inc_list.append(inc)

    except UnicodeDecodeError:
        # Capture exceptions caused by non-ASCII encoded files.
        if _encoding == 'ascii':
            # Reopen the file in UTF-8 mode. Python allows a file to be opened
            # more than once at a time. Exceptions for the recursively called
            # function will be handled inside it.
            # Output a warning.
            print("ERROR:" + path + ":Non-ASCII encoded file!")
            inc_list = file_get_include_list(path,'utf-8')
        else:
            # Already tried to decode in UTF-8 mode. Don't try again.
            print("ERROR:" + path + ":Failed to decode UTF-8!")
            fatal_error = True # Can't return while file is still open.
            utils.print_exception_info()
    except:
        print("ERROR:" + path + ":error while parsing!")
        utils.print_exception_info()

    f.close()

    if fatal_error:
        return None

    return inc_list


def inc_order_is_correct(inc_list, path, commit_hash=""):
    '''Returns true if the provided list is in order. If not, output error
    messages to stdout.'''

    # If there are less than 2 includes there's no need to check.
    if len(inc_list) < 2:
        return True

    if commit_hash != "":
        commit_hash = commit_hash + ":" # For formatting

    sys_after_user = False
    sys_order_wrong = False
    user_order_wrong = False

    # First, check if all system includes are before the user includes.
    previous_delimiter = '<' # Begin with system includes.

    for inc in inc_list:
        delimiter = inc[0]
        if previous_delimiter == '<' and delimiter == '"':
            previous_delimiter = '"' # Started user includes.
        elif previous_delimiter == '"' and delimiter == '<':
            sys_after_user = True

    # Then, check alphabetic order (system and user separately).
    usr_incs = []
    sys_incs = []

    for inc in inc_list:
        if inc.startswith('<'):
            sys_incs.append(inc)
        elif inc.startswith('"'):
            usr_incs.append(inc)

    if sorted(sys_incs) != sys_incs:
         sys_order_wrong = True
    if sorted(usr_incs) != usr_incs:
         user_order_wrong = True

    # Output error messages.
    if sys_after_user:
        print("ERROR:" + commit_hash + path +
              ":System include after user include.")
    if sys_order_wrong:
        print("ERROR:" + commit_hash + path +
              ":System includes not in order.")
    if user_order_wrong:
        print("ERROR:" + commit_hash + path +
              ":User includes not in order.")

    return not ( sys_after_user or sys_order_wrong or user_order_wrong )


def file_is_correct(path):
    '''Checks whether the order of includes in the file specified in the path
    is correct or not.'''

    inc_list = file_get_include_list(path)

    if inc_list == None: # Failed to decode - Flag as incorrect.
        return False

    return inc_order_is_correct(inc_list, path)


def directory_tree_is_correct():
    '''Checks all tracked files in the current git repository, except the ones
       explicitly ignored by this script.
       Returns True if all files are correct.'''

    # Get list of files tracked by git
    (rc, stdout, stderr) = utils.shell_command([ 'git', 'ls-files' ])
    if rc != 0:
        return False

    all_files_correct = True

    files = stdout.splitlines()

    for f in files:
        if not utils.file_is_ignored(f, VALID_FILE_EXTENSIONS, IGNORED_FILES, IGNORED_FOLDERS):
            if not file_is_correct(f):
                # Make the script end with an error code, but continue
                # checking files even if one of them is incorrect.
                all_files_correct = False

    return all_files_correct


def patch_is_correct(base_commit, end_commit):
    '''Get the output of a git diff and analyse each modified file.'''

    # Get patches of the affected commits with one line of context.
    (rc, stdout, stderr) = utils.shell_command([ 'git', 'log', '--unified=1',
                                           '--pretty="commit %h"',
                                           base_commit + '..' + end_commit ])

    if rc != 0:
        return False

    # Parse stdout to get all renamed, modified and added file paths.
    # Then, check order of new includes. The log output begins with each commit
    # comment and then a list of files and differences.
    lines = stdout.splitlines()

    all_files_correct = True

    # All files without a valid extension are ignored. /dev/null is also used by
    # git patch to tell that a file has been deleted, and it doesn't have a
    # valid extension, so it will be used as a reset value.
    path = "/dev/null"
    commit_hash = "0"
    # There are only 2 states: commit msg or file. Start inside commit message
    # because the include list is not checked when changing from this state.
    inside_commit_message = True
    inc_list = []

    # Allow spaces in between, but not comments.
    # Check for lines with "+" or " " at the beginning (added or not modified)
    pattern = re.compile(r"^[+ ]\s*#\s*include\s\s*[\"<]")

    total_line_num = len(lines)
    # By iterating this way the loop can detect if it's the last iteration and
    # check the last file (the log doesn't have any indicator of the end)
    for i, line in enumerate(lines): # Save line number in i

        new_commit = False
        new_file = False
        log_last_line = i == total_line_num-1

        # 1. Check which kind of line this is. If this line means that the file
        # being analysed is finished, don't update the path or hash until after
        # checking the order of includes, they are used in error messages. Check
        # for any includes in case this is the last line of the log.

        # Line format: <"commit 0000000"> (quotes present in stdout)
        if line.startswith('"commit '): # New commit
            new_commit = True
        # Line format: <+++ b/path>
        elif line.startswith("+++ b/"): # New file.
            new_file = True
        # Any other line
        else: # Check for includes inside files, not in the commit message.
            if not inside_commit_message:
                if pattern.match(line):
                    line_remove_comments(line)
                    inc = line_get_include_path(line)
                    if inc != None:
                        inc_list.append(inc)

        # 2. Check order of includes if the file that was being analysed has
        # finished. Print hash and path of the analised file in the error
        # messages.

        if new_commit or new_file or log_last_line:
            if not inside_commit_message: # If a file is being analysed
                if not utils.file_is_ignored(path, VALID_FILE_EXTENSIONS,
                        IGNORED_FILES, IGNORED_FOLDERS):
                    if not inc_order_is_correct(inc_list, path, commit_hash):
                        all_files_correct = False
            inc_list = [] # Reset the include list for the next file (if any)

        # 3. Update path or hash for the new file or commit. Update state.

        if new_commit: # New commit, save hash
            inside_commit_message = True # Enter commit message state
            commit_hash = line[ 8 : -1 ] # Discard last "
        elif new_file: # New file, save path.
            inside_commit_message = False # Save path, exit commit message state
            # A deleted file will appear as /dev/null so it will be ignored.
            path = line[ 6 : ]

    return all_files_correct



def parse_cmd_line(argv, prog_name):
    parser = argparse.ArgumentParser(
        prog=prog_name,
        formatter_class=argparse.RawTextHelpFormatter,
        description="Check alphabetical order of #includes",
        epilog="""
For each source file in the tree, checks that #include's C preprocessor
directives are ordered alphabetically (as mandated by the Trusted
Firmware coding style). System header includes must come before user
header includes.
""")

    parser.add_argument("--tree", "-t",
                        help="Path to the source tree to check (default: %(default)s)",
                        default=os.curdir)
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

    if args.patch:
        print("Checking files modified between patches " + args.from_ref
              + " and " + args.to_ref + "...")
        if not patch_is_correct(args.from_ref, args.to_ref):
            sys.exit(1)
    else:
        print("Checking all files in directory '%s'..." % os.path.abspath(args.tree))
        if not directory_tree_is_correct():
            sys.exit(1)

    # All source code files are correct.
    sys.exit(0)
