#!/usr/bin/env bash
#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source "$ci_root/fvp_utils.sh"

n1sdp_prebuilts=${n1sdp_prebuilts:="$tfa_downloads/css/n1sdp"}
scp_mcp_prebuilts=${scp_mcp_prebuilts:="$scp_mcp_downloads/n1sdp/release"}

get_n1sdp_firmware() {
        url=$n1sdp_firmware_bin_url saveas="n1sdp-board-firmware.zip" fetch_file
        archive_file "n1sdp-board-firmware.zip"
}

gen_recovery_image_n1sdp() {
        local zip_dir="$workspace/$mode/n1sdp-board-firmware_primary"
        local zip_file="${zip_dir}.zip"

        mkdir -p "$zip_dir"

        extract_tarball "$archive/n1sdp-board-firmware.zip" "$zip_dir"

        cp -Rp --no-preserve=ownership "$archive/mcp_fw.bin" "$zip_dir/SOFTWARE"
        cp -Rp --no-preserve=ownership "$archive/mcp_rom.bin" "$zip_dir/SOFTWARE"
        cp -Rp --no-preserve=ownership "$archive/scp_fw.bin" "$zip_dir/SOFTWARE"
        cp -Rp --no-preserve=ownership "$archive/scp_rom.bin" "$zip_dir/SOFTWARE"

        (cd "$zip_dir" && zip -rq "$zip_file" -- *)

        archive_file "$zip_file"
}

gen_n1sdp_yaml() {
        local yaml_file="$workspace/n1sdp.yaml"
        local job_file="$workspace/job.yaml"
        local payload_type="${payload_type:?}"

        bin_mode="$mode" \
                "$ci_root/script/gen_n1sdp_${payload_type}_yaml.sh" > "$yaml_file"

        cp "$yaml_file" "$job_file"
        archive_file "$yaml_file"
        archive_file "$job_file"
}
