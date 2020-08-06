#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Install PyGitHub if needed
python3 -c "import github"
if [ $? != 0 ]
then
	yes | pip3 install pygithub
fi

# Run bot
python3 $(dirname "${BASH_SOURCE[0]}")/github_pr_bot.py $@
