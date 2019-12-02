#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# This file contains common model controls and parameters across *ALL* FVP
# models.

default_var pctl_startup 0.0.0.0
default_var quantum 1000

reset_var cache_state_modelled
reset_var has_bl1
reset_var has_fip
reset_var preload_bl33
reset_var reset_to_bl31
reset_var reset_to_spmin
reset_var secure_memory
reset_var secure_ram_fill


if [ "$bl2_at_el3" ]; then
	has_fip=1
elif [ -z "$reset_to_spmin" -a -z "$reset_to_bl31" ]; then
	has_bl1=1
	has_fip=1
fi

cat <<EOF >"$model_param_file"

-C bp.ve_sysregs.exit_on_shutdown=1
-C pctl.startup=$pctl_startup

${secure_memory+-C bp.secure_memory=$secure_memory}
${cache_state_modelled+-C cache_state_modelled=$cache_state_modelled}

${secure_ram_fill+-C bp.secureSRAM.fill1=0x00000000}
${secure_ram_fill+-C bp.secureSRAM.fill2=0x00000000}

${bl2_at_el3+--data cluster0.cpu0=$bl2_bin@${bl2_addr:?}}

${reset_to_bl31+--data cluster0.cpu0=$bl31_bin@${bl31_addr:?}}
${preload_bl33+--data cluster0.cpu0=$preload_bl33_bin@${bl33_addr:?}}

${reset_to_spmin+--data cluster0.cpu0=$bl32_bin@${bl32_addr:?}}
${reset_to_spmin+--data cluster0.cpu0=$uboot_bin@${bl33_addr:?}}

${memprotect+--data cluster0.cpu0=$memprotect@${memprotect_addr:?}}
${romlib_bin+--data cluster0.cpu0=$romlib_bin@${romlib_addr:?}}

${has_bl1+-C bp.secureflashloader.fname=$bl1_bin}
${has_fip+-C bp.flashloader0.fname=$fip_bin}

${dtb_bin+--data cluster0.cpu0=$dtb_bin@${dtb_addr:?}}
${kernel_bin+--data cluster0.cpu0=$kernel_bin@${kernel_addr:?}}
${initrd_bin+--data cluster0.cpu0=$initrd_bin@${initrd_addr:?}}

${ns_bl1u_bin+--data cluster0.cpu0=$ns_bl1u_bin@$ns_bl1u_addr}
${fwu_fip_bin+--data cluster0.cpu0=$fwu_fip_bin@$fwu_fip_addr}
${backup_fip_bin+--data cluster0.cpu0=$backup_fip_bin@$backup_fip_addr}

${flashloader1_bin+-C bp.flashloader1.fname=$flashloader1_bin}
${rootfs_bin+-C bp.virtioblockdevice.image_path=$rootfs_bin}

${uart0_out+-C bp.pl011_uart0.out_file=$uart0_out}
${uart0_out+-C bp.pl011_uart0.unbuffered_output=1}

${no_quantum--Q ${quantum}}

EOF
