Scripts that Generate Graphs
============================

This directory contains scripts that generate graphs. Each script is run with
bash and may require additional tools. All of the scripts require gnuplot.

All scripts produce a PNG graph on stdout and the data on stderr.

Test Runs by category
---------------------

The script `categorize-tests.bash`, and its associated awk and plot scripts,
generate a stacked bar chart with bars representing groups of tests (l1 l2,
etc.) and segments of the bars representing types. `categorize-tests.bash`
accepts an argument to filter the tests included with grep.

For example, the following will produce a graph of the juno-specific tests:

    bash categorize-tests.bash juno > juno-tests.png 2> juno-tests.txt

Lines of Code by Module
-----------------------

The script `sloc-viz.bash`, and its associated plot script, generate a stacked
bar chart where each bar is a module and the bars' segments represent programming
languages (or documentation languages). This script will produce a graph for
whatever directory it's run within, and has special logic that includes more
detail when run from the Trusted Firmware - A project's root directory.

This script has additional requirements:
* ``tokei`` - a quick source lines of code counting tool
* ``jq`` - a JSON query language for the command line, version 1.6 or later
  as the ``--jsonargs`` option is required

For example, when run from the root of TF-A, the following commandline will graph
sloc of TF-A:

    bash ../<this-repo>/script/graph/sloc-viz.bash > sloc.png 2> sloc.tsv

*Copyright (c) 2021, Arm Limited. All rights reserved.*
