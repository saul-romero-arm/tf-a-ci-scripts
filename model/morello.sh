#!/usr/bin/env bash
#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/SubSystemModels/$model_version/$model_build/models/$model_flavour/FVP_Morello"

cat <<EOF >"$model_param_file"
--data Morello_Top.css.scp.armcortexm7ct=$archive/scp_rom.bin@0x0
--data Morello_Top.css.mcp.armcortexm7ct=$archive/mcp_rom.bin@0x0
-C Morello_Top.soc.scp_qspi_loader.fname=$scp_fw_bin
-C Morello_Top.soc.mcp_qspi_loader.fname=$mcp_fw_bin
--data $uefi_bin@${uefi_addr:?}
-C board.virtioblockdevice.image_path=$busybox_bin
${uart1_out+-C css.pl011_uart_ap.out_file=$uart1_out}
${uart1_out+-C css.pl011_uart_ap.unbuffered_output=1}
${uart2_out+-C css.scp.pl011_uart_scp.out_file=$uart2_out}
${uart0_out+-C css.mcp.pl011_uart0_mcp.out_file=$uart0_out}
-C css.scp.armcortexm7ct.INITVTOR=0x0
-C css.mcp.armcortexm7ct.INITVTOR=0x0
-C board.virtio_rng.enabled=1
-C board.virtio_rng.seed=0
-C displayController=0
-C num_clusters=2
-C num_cores=2
-C css.diagnostics=4
EOF
