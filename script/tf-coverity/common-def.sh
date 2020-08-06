#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

JENKINS_URL=https://jenkins.oss.arm.com/

# mbed TLS source tag to checkout when building Trusted Firmware with Trusted
# Board Boot support.
MBED_TLS_SOURCES_TAG="mbedtls-2.18.0"

ARMCLANG_PATH=/arm/warehouse/Distributions/FA/ARMCompiler/6.8/25/standalone-linux-x86_64-rel/bin/armclang
CRYPTOCELL_LIB_PATH=/arm/projectscratch/ssg/trusted-fw/dummy-crypto-lib
