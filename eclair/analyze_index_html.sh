#!/bin/bash
#
# Copyright (c) 2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Template to produce index.html for the "full" build.

cat <<EOF >index.html
<html>
<body>
<h1>MISRA reports</h1>

<p>
TF-A Config: ${TF_CONFIG}<br />
CI Build: <a href="${BUILD_URL}">${BUILD_URL}</a>
</p>

<li><a href="ECLAIR/full_txt/">Full TXT report</a>
<li><a href="ECLAIR/full_html/index.html">Full HTML report</a>
<li><a href="ECLAIR/full_html/by_service.html#strictness/service/first_file&strictness">Report by issue strictness (Mandatory/Required/Advisory) (HTML).</a>
</body>
</html>
EOF
