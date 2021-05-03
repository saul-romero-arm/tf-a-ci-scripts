#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# If we exit from a secondary uart, and if that had lots of prints, then the
# model will stall. See: https://jira.arm.com/browse/SDDKW-43675. So, we wait
# here expect for something that never arrives.

# TODO
