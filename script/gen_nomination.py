#!/usr/bin/env python3
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# This script examines the checked out copy of a Git repository, inspects the
# touched files in a commit, and then determines what test configs are suited to
# be executed when testing the repository.
#
# The test nominations are based on the paths touched in a commit: for example,
# when foo/bar is touched, run test blah:baz. All nominations are grouped under
# NOMINATED directory.
#
# The script must be invoked from within a Git clone.

import argparse
import functools
import os
import re
import subprocess
import sys


class Commit:
    # REs to identify differ header
    diff_re = re.compile(r"[+-]")
    hunk_re = re.compile(r"(\+{3}|-{3}) [ab]/")

    # A diff line looks like a diff, of course, but is not a hunk header
    is_diff = lambda l: Commit.diff_re.match(l) and not Commit.hunk_re.match(l)

    def __init__(self, refspec):
        self.refspec = refspec

    @functools.lru_cache()
    def touched_files(self, parent):
        git_cmd = ("git diff-tree --no-commit-id --name-only -r " +
                self.refspec).split()
        if parent:
            git_cmd.append(parent)

        return subprocess.check_output(git_cmd).decode(encoding='UTF-8').split(
                "\n")

    @functools.lru_cache()
    def diff_lines(self, parent):
        against = parent if parent else (self.refspec + "^")
        git_cmd = "git diff {} {}".format(against, self.refspec).split()

        # Filter valid diff lines from the git diff output
        return list(filter(Commit.is_diff, subprocess.check_output(
                git_cmd).decode(encoding="UTF-8").split("\n")))

    def matches(self, rule, parent):
        if type(rule) is str:
            scheme, colon, rest = rule.partition(":")
            if colon != ":":
                raise Exception("rule {} doesn't have a scheme".format(rule))

            if scheme == "path":
                # Rule is path in plain string
                return any(f.startswith(rest) for f in self.touched_files(parent))
            elif scheme == "pathre":
                # Rule is a regular expression matched against path
                regex = re.compile(rest)
                return any(regex.search(f) for f in self.touched_files(parent))
            elif scheme == "has":
                # Rule is a regular expression matched against the commit diff
                has_upper = any(c.isupper() for c in rule)
                pat_re = re.compile(rest, re.IGNORECASE if not has_upper else 0)

                return any(pat_re.search(l) for l in self.diff_lines(parent))
            elif scheme == "op":
                pass
            else:
                raise Exception("unsupported scheme: " + scheme)
        elif type(rule) is tuple:
            # If op:match-all is found in the tuple, the tuple must match all
            # rules (AND).
            test = all if "op:match-all" in rule else any

            # If the rule is a tuple, we match them individually
            return test(self.matches(r, parent) for r in rule)
        else:
            raise Exception("unsupported rule type: {}".format(type(rule)))


ci_root = os.path.abspath(os.path.join(__file__, os.pardir, os.pardir))
group_dir = os.path.join(ci_root, "group")

parser = argparse.ArgumentParser()

# Argument setup
parser.add_argument("--parent", help="Parent commit to compare against")
parser.add_argument("--refspec", default="@", help="refspec")
parser.add_argument("rules_file", help="Rules file")

opts = parser.parse_args()

# Import project-specific nomination_rules dictionary
script_dir = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(opts.rules_file)) as fd:
    exec(fd.read())

commit = Commit(opts.refspec)
nominations = set()
for rule, test_list in nomination_rules.items():
    # Rule must be either string or tuple. Test list must be list
    assert type(rule) is str or type(rule) is tuple
    assert type(test_list) is list

    if commit.matches(rule, opts.parent):
        nominations |= set(test_list)

for nom in nominations:
    # Each test nomination must exist in the repository
    if not os.path.isfile(os.path.join(group_dir, nom)):
        raise Exception("nomination {} doesn't exist".format(nom))

    print(nom)
