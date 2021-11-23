Scripts that Generate Graphs
============================

This directory contains scripts that generate graphs. Each script is run with
bash and may require additional tools. All of the scripts require gnuplot.

All scripts produce a PNG graph on stdout and the data on stderr.

Tests by Category
-----------------

The script `categorize-tests.bash`, and its associated awk and plot scripts,
generate a stacked bar chart with bars representing groups of tests (L1 L2,
etc.) and segments of the bars representing types. ``categorize-tests.bash``
accepts an argument to filter the tests included with grep.

For example, the following will produce a graph of the Juno-specific tests:

.. code-block::

    bash categorize-tests.bash juno > juno-tests.png 2> juno-tests.txt

Lines of Code by Module
-----------------------

The script ``sloc-viz.bash``, and its associated plot script, generate a stacked
bar chart where each bar is a module and the bars' segments represent
programming languages (or documentation languages). This script will produce a
graph for whatever directory it's run within, and has special logic that
includes more detail when run from the Trusted Firmware - A project's root
directory.

This script has additional requirements:

* ``tokei`` - a quick source lines of code counting tool
* ``jq`` - a JSON query language for the command line, version 1.6 or later
  as the ``--jsonargs`` option is required

For example, when run from the root of TF-A, the following command line will
graph SLOC of TF-A:

.. code-block::

    bash ../<this-repo>/script/graphs/sloc-viz.bash > sloc.png 2> sloc.tsv

Test Results
------------

The script `tf-main-results.bash` uses curl to retrieve test results for a
tf-a-main Jenkins job, and generates a CSV and stacked histogram PNG of the
combined data.

Usage:
======

    bash tf-main-results.bash <jenkins-url> [ci_gateway] [filter]

The Jenkins URL is the URL for the target build job.

    https://ci.trustedfirmware.org/job/tf-a-main/1/

The sub-builds for this job will all be queried to find the ones that contain
tests, ignoring child builds that only build and don't run any platform tests.

`tf-a-ci-gateway` is the default gateway, although, different gateways may be
specified with the optional "ci_gateway" argument. This option will be combined
with the build numbers and the base Jenkins URL to retrieve the results of
sub-builds.

This can be filtered further using the optional "filter" argument, which will
select only test groups that match the provided regex.

Example Useful Queries
======================

Only show tests running the test framework:

    bash tf-main-results.bash <jenkins-url> [ci_gateway] "tftf"

Only show tests for N1SDP & Juno platforms:

    bash tf-main-results.bash <jenkins-url> [ci_gateway] "n1sdp|juno"

Only show boot tests on FVP platforms:

    bash tf-main-results.bash <jenkins-url> [ci_gateway] 'fvp.*boot'

Note: for filters that return a small number of test groups, the graph is not
ideal as it is sized for a large number. A CSV file of the data is also produced,
however, so that you can use it to create your own graph, if required.

Additional Config
=================

The script also allows the three output files to be configured via ENV variables:

    PNGFILE=out.png CSVFILE=out.csv bash tf-main-results.bash

If they are not set then default values based on the build number will be generated:

    PNGFILE_DEFAULT="tf-main_${build_number}.png"
    CSVFILE_DEFAULT="tf-main_${build_number}.csv"

If any of these files already exist then they will be overwritten.

*Copyright (c) 2021-2022, Arm Limited. All rights reserved.*
