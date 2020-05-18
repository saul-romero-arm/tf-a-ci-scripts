#!/usr/bin/env python3
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import os
import subprocess
import sys
import textwrap


def dir_is_ignored(relative_path, ignored_folders):
    '''Checks if a directory is on the ignore list or inside one of the ignored
    directories. relative_path mustn't end in "/".'''

    # Check if directory is in ignore list
    if relative_path in ignored_folders:
        return True

    # Check if directory is a subdirectory of one in ignore list
    return (relative_path + '/').startswith(ignored_folders)


def file_is_ignored(relative_path, valid_file_extensions, ignored_files, ignored_folders):
    '''Checks if a file is ignored based on its folder, name and extension.'''
    if not relative_path.endswith(valid_file_extensions):
        return True

    if relative_path in ignored_files:
        return True

    return dir_is_ignored(os.path.dirname(relative_path), ignored_folders)


def print_exception_info():
    '''Print some information about the cause of an exception.'''
    print("ERROR: Exception:")
    print(textwrap.indent(str(sys.exc_info()[0]),"      "))
    print(textwrap.indent(str(sys.exc_info()[1]),"      "))


def decode_string(string, encoding='utf-8'):
    '''Tries to decode a binary string. It gives an error if it finds
    invalid characters, but it will return the string converted anyway,
    ignoring these characters.'''
    try:
        string = string.decode(encoding)
    except UnicodeDecodeError:
        # Capture exceptions caused by invalid characters.
        print("ERROR:Non-{} characters detected.".format(encoding.upper()))
        print_exception_info()
        string = string.decode(encoding, "ignore")

    return string


def shell_command(cmd_line):
    '''Executes a shell command. Returns (returncode, stdout, stderr), where
    stdout and stderr are strings.'''

    try:
        p = subprocess.Popen(cmd_line, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
        (stdout, stderr) = p.communicate()
        # No need for p.wait(), p.communicate() does it by default.
    except:
        print("ERROR: Shell command: ", end="")
        print(cmd_line)
        print_exception_info()
        return (1, None, None)

    stdout = decode_string(stdout)
    stderr = decode_string(stderr)

    if p.returncode != 0:
        print("ERROR: Shell command failed:")
        print(textwrap.indent(str(cmd_line),"      "))
        print("ERROR: stdout:")
        print(textwrap.indent(stdout,"      "))
        print("ERROR: stderr:")
        print(textwrap.indent(stderr,"      "))

    return (p.returncode, stdout, stderr)

