#!/usr/bin/env python3
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import argparse
import json
import re
import shutil
import sys


_rule_exclusions = [
    "MISRA C-2012 Rule 2.4",
    "MISRA C-2012 Rule 2.5",
    "MISRA C-2012 Rule 2.7",
    "MISRA C-2012 Rule 5.1",
    "MISRA C-2012 Rule 5.8",
    "MISRA C-2012 Rule 8.6",
    "MISRA C-2012 Rule 8.7",
    "MISRA C-2012 Rule 11.4",
    "MISRA C-2012 Rule 11.5",
    "MISRA C-2012 Rule 15.1",
    "MISRA C-2012 Rule 15.5",
    "MISRA C-2012 Rule 15.6",
    "MISRA C-2012 Rule 16.1",
    "MISRA C-2012 Rule 16.3",
    "MISRA C-2012 Rule 17.1",
    "MISRA C-2012 Rule 21.6",
    "MISRA C-2012 Directive 4.6",
    "MISRA C-2012 Directive 4.8",
    "MISRA C-2012 Directive 4.9"
]

# The following classification of rules and directives include 'MISRA C:2012
# Amendment 1'

# Directives
_dir_required = set(["1.1", "2.1", "3.1", "4.1", "4.3", "4.7", "4.10", "4.11",
    "4.12", "4.14"])

_dir_advisory = set(["4.2", "4.4", "4.5", "4.6", "4.8", "4.9", "4.13"])

# Rules
_rule_mandatory = set(["9.1", "9.2", "9.3", "12.5", "13.6", "17.3", "17.4",
    "17.6", "19.1", "21.13", "21.17", "21.18", "21.19", "21.20", "22.2", "22.5",
    "22.6"])

_rule_required = set(["1.1", "1.3", "2.1", "2.2", "3.1", "3.2", "4.1", "5.1",
    "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8", "6.1", "6.2", "7.1", "7.2",
    "7.3", "7.4", "8.1", "8.2", "8.3", "8.4", "8.5", "8.6", "8.7", "8.8",
    "8.10", "8.12", "8.14", "9.2", "9.3", "9.4", "9.5", "10.1", "10.2", "10.3",
    "10.4", "10.6", "10.7", "10.8", "11.1", "11.2", "11.3", "11.6", "11.7",
    "11.8", "11.9", "12.2", "13.1", "13.2", "13.5", "14.1", "14.2", "14.3",
    "14.4", "15.2", "15.3", "15.6", "15.7", "16.1", "16.2", "16.3", "16.4",
    "16.5", "16.6", "16.7", "17.1", "17.2", "17.7", "18.1", "18.2", "18.3",
    "18.6", "18.7", "18.8", "20.3", "20.4", "20.6", "20.7", "20.8", "20.9",
    "20.11", "20.12", "20.13", "20.14", "21.1", "21.2", "21.3", "21.4", "21.5",
    "21.6", "21.7", "21.8", "21.9", "21.10", "21.11", "21.14", "21.15", "21.16",
    "22.1", "22.3", "22.4", "22.7", "22.8", "22.9", "22.10"])

_rule_advisory = set(["1.2", "2.3", "2.4", "2.5", "2.6", "2.7", "4.2", "5.9",
    "8.9", "8.11", "8.13", "10.5", "11.4", "11.5", "12.1", "12.3", "12.4",
    "13.3", "13.4", "15.1", "15.4", "15.5", "17.5", "17.8", "18.4", "18.5",
    "19.2", "20.1", "20.2", "20.5", "20.10", "21.12"])


_checker_lookup = {
        "Directive": {
            "required": _dir_required,
            "advisory": _dir_advisory
        },
        "Rule": {
            "mandatory": _rule_mandatory,
            "required": _rule_required,
            "advisory": _rule_advisory
        }
    }

_checker_re = re.compile(r"""(?P<kind>\w+) (?P<number>[\d\.]+)$""")


def _classify_checker(checker):
    match = _checker_re.search(checker)
    if match:
        kind, number = match.group("kind"), match.group("number")
        for classification, class_set in _checker_lookup[kind].items():
            if number in class_set:
                return classification

    return "unknown"


# Return a copy of the original issue description. Update file path to strip
# heading '/', and also insert CID.
def _new_issue(cid, orig_issue):
    checker = orig_issue["checker"]
    classification = _classify_checker(checker)

    return {
        "cid": cid,
        "file": orig_issue["file"].lstrip("/"),
        "line": orig_issue["mainEventLineNumber"],
        "checker": checker,
        "classification": classification,
        "description": orig_issue["mainEventDescription"]
    }


def _cls_string(issue):
    cls = issue["classification"]

    return " (" + cls + ")" if cls != "unknown" else ""


# Given an issue, make a string formed of file name, line number, checker, and
# the CID. This could be used as a dictionary key to identify unique defects
# across the scan. Convert inegers to zero-padded strings for proper sorting.
def make_key(i):
    return (i["file"] + str(i["line"]).zfill(5) + i["checker"] +
            str(i["cid"]).zfill(5))


# Iterate through all issues that are not ignored. If show_all is set, only
# issues that are not in the comparison snapshot are returned.
def iter_issues(path, show_all=False):
    with open(path, encoding="utf-8") as fd:
        report = json.load(fd)

    # Unconditional filter
    filters = [lambda i: ((i["triage"]["action"] != "Ignore") and
            (i["occurrences"][0]["checker"] not in _rule_exclusions))]

    # Whether we need diffs only
    if not show_all:
        # Pick only issues that are not present in comparison snapshot
        filters.append(lambda i: not i["presentInComparisonSnapshot"])

    # Pick issue when all filters are true
    filter_func = lambda i: all([f(i) for f in filters])

    # Top-level is a group of issues, all sharing a common CID
    for issue_group in filter(filter_func, report["issueInfo"]):
        # Pick up individual occurrence of the CID
        for occurrence in issue_group["occurrences"]:
            yield _new_issue(issue_group["cid"], occurrence)


# Format issue (returned from iter_issues()) as text.
def format_issue(issue):
    return ("{file}:{line}:[{checker}{cls}]<{cid}> {description}").format_map(
            dict(issue, cls=_cls_string(issue)))


# Format issue (returned from iter_issues()) as HTML table row.
def format_issue_html(issue):
    cls = _cls_string(issue)
    cov_class = "cov-" + issue["classification"]

    return """\
<tr class="{cov_class}">
  <td class="cov-file">{file}</td>
  <td class="cov-line">{line}</td>
  <td class="cov-checker">{checker}{cls}</td>
  <td class="cov-cid">{cid}</td>
  <td class="cov-description">{description}</td>
</tr>""".format_map(dict(issue, cls=cls, cov_class=cov_class))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--all", default=False, dest="show_all",
            action="store_const", const=True, help="List all issues")
    parser.add_argument("--output",
            help="File to output filtered defects to in JSON")
    parser.add_argument("json_report")

    opts = parser.parse_args()

    issues = []
    for issue in sorted(iter_issues(opts.json_report, opts.show_all),
            key=lambda i: make_key(i)):
        print(format_issue(issue))
        issues.append(issue)

    if opts.output:
        # Dump selected issues
        with open(opts.output, "wt") as fd:
            fd.write(json.dumps(issues))

    sys.exit(int(len(issues) > 0))
