#!/usr/bin/env python3
#
# Copyright (c) 2022, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import argparse
import csv
import os

from gen_test_report import emit_header, print_error_message

TABLE_HEADER = """\
<table id="tf-results-panel">
  <tbody>
    <tr>
      <td class="results-col">
        <table>
          <tbody>
            <thead>
              <tr>
                <th>Passed</th>
                <th>Skipped</th>
                <th>Crashed</th>
                <th>Failed</th>
              </tr>
            </thead>
            <tbody>
              <tr>"""

TABLE_FOOTER = """\
              </tr>
            </tbody>
          </tbody>
        </table>
      </td>
      <td class="button-col">
        <button id="tf-download-button" onclick="window.open('{}','_blank')">Download Plot</button>
      </td>
    </tr>
  </tbody>
</table>"""

# Open and sum the results of a comma-separated test result file.
def fetch_results(csv_path):
    failed = passed = skipped = crashed = 0
    with open(csv_path, "r") as fd:
        for test in csv.DictReader(fd):
            failed = failed + int(test["Failed"])
            passed = passed + int(test["Passed"])
            skipped = skipped + int(test["Skipped"])
            crashed = crashed + int(test["Crashed"])
    return passed, skipped, crashed, failed


def main(fd, csv_path, png_path):
    results_row = ("""<td>{}</td>\n""".rjust(28) * 4).format(
        *fetch_results(csv_path)
    )

    # Emite header and style sheet.
    emit_header(fd)

    print(TABLE_HEADER, file=fd)
    print(results_row, file=fd)

    # Format table button to link to full-size plot of results.
    print(TABLE_FOOTER.format(build_url + png_path), file=fd)


if __name__ == "__main__":
    global build_url

    parser = argparse.ArgumentParser()

    # Add arguments
    parser.add_argument(
        "--output",
        "-o",
        default="report.html",
        help="Path to output file",
    )
    parser.add_argument(
        "--csv",
        default=None,
        help="Path to input CSV with data for the target job",
    )
    parser.add_argument(
        "--png", default=None, help="Filename for PNG results plot"
    )

    # The build url and target for the results are needed in-case the user hasn't provided a
    # paths to the inputs.
    opts = parser.parse_args()
    build_url = os.environ["BUILD_URL"]
    target_job = os.environ["TARGET_BUILD"]
    target_job_name = target_job[: target_job.find("/")]

    # Use filenames provided by user or try and infer based off the target name from the environment.
    output_path = "report.html" if not opts.output else opts.output
    csv_path = target_job_name + "results.csv" if not opts.csv else opts.csv
    png_path = target_job_name + "results.png" if not opts.png else opts.png

    with open(output_path, "w") as fd:
        try:
            main(fd, csv_path, png_path)
        except:
            print_error_message(fd)
            raise
