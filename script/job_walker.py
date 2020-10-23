#!/usr/bin/env python3
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# This script is used to walk a job tree, primarily to identify sub-jobs
# triggered by a top-level job.
#
# The script works by scraping console output of jobs, starting from the
# top-level one, sniffing for patterns indicative of sub-jobs, and following the
# trail.

import argparse
import contextlib
import re
import sys
import urllib.request

# Sub-job patters. All of them capture job name (j) and build number (b).
_SUBJOB_PATTERNS = (
        # Usualy seen on freestyle jobs
        re.compile(r"(?P<j>[-a-z_]+) #(?P<b>[0-9]+) completed. Result was (?P<s>[A-Z]+)",
            re.IGNORECASE),

        # Usualy seen on multi-phase jobs
        re.compile(r"Finished Build : #(?P<b>[0-9]+) of Job : (?P<j>[-a-z_]+) with status : (?P<s>[A-Z]+)",
            re.IGNORECASE)
)


# Generator that yields lines on a job console as strings
def _console_lines(console_url):
    with urllib.request.urlopen(console_url) as console_fd:
        for line in filter(None, console_fd):
            # Console might have special characters. Yield an empty line in that case.
            try:
                yield line.decode().rstrip("\n")
            except UnicodeDecodeError as e:
                # In case of decode error, return up until the character that
                # caused the error
                yield line[:e.start].decode().rstrip("\n")


# Class representing Jenkins job
class JobInstance:
    def __init__(self, url, status=None):
        self.sub_jobs = []
        self.url = url
        self.name = None
        self.build_number = None
        self.config = None
        self.status = status
        self.depth = 0

    # Representation for debugging
    def __repr__(self):
        return "{}#{}".format(self.name, self.build_number)

    # Scrape job's console to identify sub jobs, and recurseively parse them.
    def parse(self, *, depth=0):
        url_fields = self.url.rstrip("/").split("/")

        # Identify job name and number from the URL
        try:
            stem_url_list = url_fields[:-3]
            self.name, self.build_number = url_fields[-2:]
            if self.build_number not in ("lastBuild", "lastSuccessfulBuild"):
                int(self.build_number)
        except:
            raise Exception(self.url + " is not a valid Jenkins build URL.")

        self.depth = depth

        # Scrape the job's console
        console_url = "/".join(url_fields + ["consoleText"])
        try:
            for line in _console_lines(console_url):
                # A job that prints CONFIGURATION is where we'd find the build
                # artefacts
                fields = line.split()
                if len(fields) == 2 and fields[0] == "CONFIGURATION:":
                    self.config = fields[1]
                    return

                # Look for sub job pattern, and recurse into the sub-job
                child_matches = filter(None, map(lambda p: p.match(line),
                    _SUBJOB_PATTERNS))
                for match in child_matches:
                    child = JobInstance("/".join(stem_url_list +
                        ["job", match.group("j"), match.group("b")]),
                        match.group("s"))
                    child.parse(depth=depth+1)
                    self.sub_jobs.append(child)
        except urllib.error.HTTPError:
            print(console_url + " is not accessible.", file=sys.stderr)

    # Generator that yields individual jobs in the hierarchy
    def walk(self, *, sort=False):
        if not self.sub_jobs:
            yield self
        else:
            descendants = self.sub_jobs
            if sort:
                descendants = sorted(self.sub_jobs, key=lambda j: j.build_number)
            for child in descendants:
                yield from child.walk(sort=sort)

    # Print one job
    def print(self):
        config_str = "[" + self.config + "]" if self.config else ""
        status = self.status if self.status else ""

        print("{}{} #{} {} {}".format(" " * 2 * self.depth, self.name,
            self.build_number, status, config_str))

    # Print the whole hierarchy
    def print_tree(self, *, sort=False):
        self.print()
        if not self.sub_jobs:
            return

        descendants = self.sub_jobs
        if sort:
            descendants = sorted(self.sub_jobs, key=lambda j: j.build_number)
        for child in descendants:
            child.print_tree(sort=sort)

    @contextlib.contextmanager
    def open_artefact(self, path, *, text=False):
        # Wrapper class that offer string reads from a byte descriptor
        class TextStream:
            def __init__(self, byte_fd):
                self.byte_fd = byte_fd

            def read(self, sz=None):
                return self.byte_fd.read(sz).decode("utf-8")

        art_url = "/".join([self.url, "artifact", path])
        with urllib.request.urlopen(art_url) as fd:
            yield TextStream(fd) if text else fd



# When invoked from command line, print the whole tree
if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("build_url",
            help="URL to specific build number to walk")
    parser.add_argument("--unique-tf-configs", default=False,
            action="store_const", const=True, help="Print unique TF configs")

    opts = parser.parse_args()

    top = JobInstance(opts.build_url)
    top.parse()

    if opts.unique_tf_configs:
        unique_configs = set()

        # Extract the base TF config name from the job's config, which contains
        # group, TFTF configs etc.
        for job in filter(lambda j: j.config, top.walk()):
            unique_configs.add(job.config.split("/")[1].split(":")[0].split(",")[0])

        for config in sorted(unique_configs):
            print(config)
    else:
        top.print_tree()
