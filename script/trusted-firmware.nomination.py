#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#
# Nomination map for Trusted Firmware.
#
# This file is EXECED from gen_nomination.py

nomination_rules = {
        # Run RDN1EDGE TF-A Tests for any platform changes
        "path:plat/arm/board/rdn1edge":
            ["tf-l3-boot-tests-css/fvp-rdn1edge-tbb,fvp-rdn1edge-default:fvp-tftf-fip.tftf-rdn1edge"],

        # Run SGI575 boot test and TF-A Tests for any platform changes
        "path:plat/arm/board/sgi575":
            ["tf-l3-boot-tests-css/fvp-sgi575-tbb:fvp-linux.sgi-fip.sgi-sgi575-debug",
             "tf-l3-boot-tests-css/fvp-sgi575-tbb,fvp-sgi575-default:fvp-tftf-fip.tftf-sgi575"],

        # Run SGM775 boot test for any platform changes
        "path:plat/arm/board/sgm775":
            ["tf-l3-boot-tests-css/fvp-sgm775-tbb:fvp-linux.sgm-dtb.sgm775-fip.sgm-sgm775-debug"],

        # Run SDEI boot test for SDEI, EHF, or RAS changes or mention
        ("pathre:sdei", "pathre:ehf", "pathre:ras", "has:SDEI_SUPPORT",
              "has:EL3_EXCEPTION_HANDLING"):
            ["tftf-l2-tests/fvp-aarch64-sdei,fvp-default:fvp-tftf-fip.tftf-aemv8a-debug"],

        }
