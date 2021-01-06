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

*Copyright (c) 2021, Arm Limited. All rights reserved.*
