#!/usr/bin/env python3
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# Given URL to a job instance, this script walks the job hierarchy, and inspects
# for Coverity scan report. CIDs from individual reports are collected and
# printed as a summary of defects for the entire scan.

import argparse
import coverity_parser
import job_walker
import json
import sys
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument("build_url",
    help="URL to specific build number to walk")
opts = parser.parse_args()

# Parse the given job
top = job_walker.JobInstance(opts.build_url)
top.parse()

# Iterate through terminal jobs, i.e., those with a config, viz. tf-worker
merged_issues = {}
for job in filter(lambda j: j.config, top.walk()):
    # Collect CIDs from archived defects.json
    try:
        # Open json as text, not bytes
        with job.open_artefact("defects.json", text=True) as fd:
            issues = json.load(fd)
    except urllib.error.HTTPError:
        print("warning: unable to read defects.json from " + job.url,
                file=sys.stderr)
        continue

    merged_issues.update({coverity_parser.make_key(i): i for i in issues})

# Sort merged issues by file name, line number, checker, and then CID.
sorted_issue_keys = sorted(merged_issues.keys())

if sorted_issue_keys:
    # Generate HTML table with issue description
    print("""
<style>
#coverity-table {
  display: block;
  max-height: 600px;
  overflow-y: auto;
}
#coverity-table thead td {
  font-weight: bold;
}
#coverity-table td {
  font-size: 0.9em;
}
#coverity-table .cov-file {
  color: brown;
}
#coverity-table .cov-line {
  color: darkviolet;
}
#coverity-table .cov-cid {
  color: orangered;
}
#coverity-table .cov-mandatory {
  background-color: #ff4d4d;
}
#coverity-table .cov-required {
  background-color: #ffcccc;
}
</style>
<table id="coverity-table" cellpadding="2">
<thead>
<tr>
  <td>File</td>
  <td>Line</td>
  <td>Checker</td>
  <td>CID</td>
  <td>Description</td>
</tr>
</thead><tbody>""")
    for key in sorted_issue_keys:
        print(coverity_parser.format_issue_html(merged_issues[key]))
    print("</tbody></table>")
    print('<div style="line-height: 3em; font-weight: bold;">{} defects reported.</div>'.format(
        len(sorted_issue_keys)))
