#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

JENKINS_URL=http://ssg-sw.cambridge.arm.com/jenkins

# mbed TLS source tag to checkout when building Trusted Firmware with Trusted
# Board Boot support.
MBED_TLS_SOURCES_TAG="mbedtls-2.16.0"

ARMCLANG_PATH=
CRYPTOCELL_LIB_PATH=/arm/projectscratch/ssg/trusted-fw/dummy-crypto-lib
