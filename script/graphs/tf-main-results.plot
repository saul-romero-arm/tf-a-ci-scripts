#
# Copyright (c) 2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Determine the number of test groups, scale the terminal based on the number
# of these.
groups=system(sprintf("awk -F ',' 'NR!=1 {print $1}' %s | sort | uniq", ARG1))
group_count=words(groups)

# Terminal height should scale with the number of groups
# (each group has a plot).
set terminal pngcairo enhanced size 5400,9600 font ',14'

set xrange [0:5<*] extend
set ytic scale 0 nomirror
set grid xtics
set lmargin 70
set bmargin 5
set yrange [:] reverse
set offsets 0,0,0.5,0.5
set datafile separator ","

set key autotitle columnhead

# Create linetypes for coloured labels
set linetype 1 linecolor "red"
set linetype 2 linecolor "black"
fill(n) = word("green red orange gray", n)

set multiplot title "TF-A CI Test Results: " . jenkins_id \
    font ",30" layout ceil(group_count/3.0),3

        set style data histograms
        set style fill solid 0.3 border -1
        set key outside left vertical
        set label "Test Suites" at screen 0.05,0.5 \
            center front rotate font ",20"

        do for [group in groups]{
                set title group font ",18"
                set style histogram rowstacked
                filter = "awk -F, 'NR==1 || $1==\"".group."\"'"
                col_count = 8
                box_width = 0.5

                plot for [col=5:col_count] '< '.filter.' '.ARG1 u col:0: \
                    (sum [i=5:col-1] column(i)): \
                    (sum [i=5:col] column(i)): \
                    ($0-box_width/2.):($0+box_width/2.):ytic(2) w boxxyerror \
                    ti columnhead(col) lc rgb fill(col-4)

                unset key
        }

unset multiplot

