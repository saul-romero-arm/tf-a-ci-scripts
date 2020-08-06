#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Install pygerrit2 if needed
python3 -c "from pygerrit2 import GerritRestAPI, HTTPBasicAuth"
if [ $? != 0 ]
then
	yes | pip3 install pygerrit2
fi

# Run bot
cd $(dirname "$0")
python3 gerrit_bot.py --user $1 --password $2 --maintainers $3
