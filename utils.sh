#!/usr/bin/env bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# This file is meant to be SOURCED only after setting $ci_root. $ci_root must be
# the absolute path to the root of the CI repository
#
# A convenient way to set ci_root from the calling script like this:
#  ci_root="$(readlink -f "$(dirname "$0")/..")"
#

# Accept root of CI location from $CI_ROOT or $ci_root, in that order
ci_root="${ci_root:-$CI_ROOT}"
ci_root="${ci_root:?}"

# Storage area to host toolchains, rootfs, tools, models, binaries, etc...
nfs_volume="${nfs_volume:-$NFS_VOLUME}"
nfs_volume="${nfs_volume:?}"

# Override workspace for local runs
workspace="${workspace:-$WORKSPACE}"
workspace="${workspace:?}"
workspace="$(readlink -f "$workspace")"
artefacts="$workspace/artefacts"

# pushd and popd outputs the directory stack every time, which could be
# confusing when shown on the log. Suppress its output.
pushd() {
	builtin pushd "$1" &>/dev/null
}
popd() {
	builtin popd &>/dev/null
}

# Copy a file to the $archive directory
archive_file() {
	local f out target md5
	f="${1:?}"

	out="${archive:?}"
	[ ! -d "$out" ] && die "$out is not a directory"

	target="$out/$(basename $f)"
	if [ -f "$target" ]; then
		# Prevent same file error
		if [ "$(stat --format=%i "$target")" = \
				"$(stat --format=%i "$f")" ]; then
			return
		fi
	fi

	md5="$(md5sum "$f" | awk '{print $1}')"
	cp -t "$out" "$f"
	echo "Archived: $f (md5: $md5)"
}

die() {
	[ "$1" ] && echo "$1" >&2
	exit 1
}

# Emit environment variables for the purpose of sourcing from shells and as
# Jenkins property files. Whether the RHS is quoted depends on "$quote".
emit_env() {
	local env_file="${env_file:?}"
	local var="${1:?}"

	# Value parameter is mandatory, but allow for it to be empty
	local val="${2?}"

	if upon "$quote"; then
		val="\"$val\""
	else
		# If RHS is not required to be quoted, any white space in it
		# won't go well with a shell sourcing this file.
		if echo "$var" | grep -q '\s'; then
			die "$var: value '$val' has white space"
		fi
	fi

	echo "$var=$val" >> "$env_file"
}

fetch_directory() {
	local base="$(basename "${url:?}")"
	local sa

	case "${url}" in
		http*://*)
			# Have exactly one trailing /
			local modified_url="$(echo "${url}" | sed 's#/*$##')/"

			# Figure out the number of components between hostname and the
			# final one
			local cut_dirs="$(echo "$modified_url" | awk -F/ '{print NF - 5}')"
			sa="${saveas:-$base}"
			echo "Fetch: $modified_url -> $sa"
			wget -rq -nH --cut-dirs="$cut_dirs" --no-parent \
				--reject="index.html*" "$modified_url"
			if [ "$sa" != "$base" ]; then
				mv "$base" "$sa"
			fi
			;;
		file://*)
			sa="${saveas:-.}"
			echo "Fetch: ${url} -> $sa"
			cp -r "${url#file://}" "$sa"
			;;
		*)
			sa="${saveas:-.}"
			echo "Fetch: ${url} -> $sa"
			cp -r "${url}" "$sa"
			;;
	esac
}

fetch_file() {
	local url="${url:?}"
	local sa
	local saveas

	if is_url "$url"; then
		saveas="${saveas-"$(basename "$url")"}"
		sa="${saveas+-o $saveas}"
		echo "Fetch: $url -> $saveas"
		# Use curl to support file protocol
		curl -sLS $sa "$url"
	else
		sa="${saveas-.}"
		echo "Fetch: $url -> $sa"
		cp "$url" "$sa"
	fi
}

# Make a temporary directory/file insdie workspace, so that it doesn't need to
# be cleaned up. Jenkins is setup to clean up workspace before a job runs.
mktempdir() {
	local ws="${workspace:?}"

	mktemp -d --tmpdir="$ws"
}
mktempfile() {
	local ws="${workspace:?}"

	mktemp --tmpdir="$ws"
}

not_upon() {
	! upon "$1"
}

# Use "$1" as a boolean
upon() {
	case "$1" in
		"" | "0" | "false") return 1;;
		*) return 0;;
	esac
}

# Check if the argument is a URL
is_url() {
	echo "$1" | grep -q "://"
}

# Check if a path is absolute
is_abs() {
	[ "${1:0:1}" = "/" ]
}

# Unset a variable based on its boolean value
# If foo=, foo will be unset
# If foo=blah, then leave it as is
reset_var() {
	local var="$1"
	local val="${!var}"

	if [ -z "$val" ]; then
		unset "$var"
	else
		var="$val"
	fi
}

default_var() {
	local var="$1"
	local val="${!var}"
	local default="$2"

	if [ -z "$val" ]; then
		eval "$var=$default"
	fi
}

# String various items joined by ":" to form a path. Items are prepended by
# default; or 'op' can be set to 'append' to have them appended.
# For example, to set: PATH=foo:bar:baz:$PATH
extend_path() {
	local path_var="$1"
	local array_var="$2"
	local path_val="${!path_var}"
	local op="${op:-prepend}"
	local sep=':'
	local array_val

	eval "array_val=\"\${$array_var[@]}\""
	array_val="$(echo ${array_val// /:})"

	[ -z "$path_val" ] && sep=''

	if [ "$op" = "prepend" ]; then
		array_val="${array_val}${sep}${path_val}"
	elif [ "$op" = "append" ]; then
		array_val="${path_val}${sep}${array_val}"
	fi

	eval "$path_var=\"$array_val\""
}

# Extract files from compressed archive to target directory. Supports .zip and
# .tar.gz format
extract_tarball() {
	local archive="$1"
	local target_dir="$2"

	pushd "$target_dir"
	case $(file --mime-type -b "$archive") in
		application/gzip)
				tar -xzf $archive
				;;
		application/zip)
				unzip -q $archive
				;;
	esac
	popd "$target_dir"
}

# Assume running on Jenkins if JENKINS_HOME is set
if [ "$JENKINS_HOME" ]; then
	jenkins_run=1
	umask 0002
else
	unset jenkins_run
fi

# Project scratch location for Trusted Firmware CI
project_filer="${nfs_volume}/projectscratch/ssg/trusted-fw"
project_scratch="${PROJECT_SCRATCH:-$project_filer/ci-workspace}"
warehouse="${nfs_volume}/warehouse"
jenkins_url="${JENKINS_URL%/*}"
jenkins_url="${jenkins_url:-https://ci.trustedfirmware.org/}"

# Model revisions
model_version="${model_version:-11.9}"
model_build="${model_build:-41}"
model_flavour="${model_flavour:-Linux64_GCC-6.4}"

# Model snapshots from filer are not normally not accessible from developer
# systems. Ignore failures from picking real path for local runs.
pinned_cortex="$(readlink -f ${pinned_cortex:-$project_filer/models/cortex})" || true
pinned_css="$(readlink -f ${pinned_css:-$project_filer/models/css})" || true

#arm_gerrit_url="gerrit.oss.arm.com"
tforg_gerrit_url="review.trustedfirmware.org"

# Repository URLs. We're using anonymous HTTP as they appear to be faster rather
# than any scheme with authentication.
#tf_ci_repo_url="http://$arm_gerrit_url/pdswinf/ci/pdcs-platforms/platform-ci"
tf_src_repo_url="${tf_src_repo_url:-$TF_SRC_REPO_URL}"
tf_src_repo_url="${tf_src_repo_url:-https://$tforg_gerrit_url/TF-A/trusted-firmware-a}"
#tf_arm_gerrit_repo="ssh://$arm_gerrit_url:29418/pdcs-platforms/ap/tf-topics.git"
tftf_src_repo_url="${tftf_src_repo_url:-$TFTF_SRC_REPO_URL}"
tftf_src_repo_url="${tftf_src_repo_url:-https://$tforg_gerrit_url/TF-A/tf-a-tests}"
#tftf_arm_gerrit_repo="ssh://$arm_gerrit_url:29418/trusted-firmware/tf-a-tests.git"
scp_src_repo_url="${scp_src_repo_url:-$SCP_SRC_REPO_URL}"
#cc_src_repo_url="${cc_src_repo_url:-https://$arm_gerrit_url/tests/lava/test-definitions.git}"
#cc_src_repo_tag="${cc_src_repo_tag:-kernel-team-workflow_2019-09-20}"

#scp_tools_src_repo_url="${scp_tools_src_repo_url:-http://$arm_gerrit_url/scp/tools-non-public}"
#tf_for_scp_tools_src_repo_url="https://gerrit.oss.arm.com/scp/test-framework"

# FIXME set a sane default for tfa_downloads
tfa_downloads="${tfa_downloads:-file:///downloads/tf-a}"
css_downloads="${css_downloads:-$tfa_downloads/css}"

linaro_1906_release="$tfa_downloads/linaro/19.06"
linaro_release="${linaro_release:-$linaro_1906_release}"

# mbedTLS archive public hosting available at github.com
mbedtls_archive="${mbedtls_archive:-https://github.com/ARMmbed/mbedtls/archive/mbedtls-2.18.0.zip}"
# The tar file contains mbedtls-mbedtls-2.18.0 repo which holds the necessary
# source files of mbedTLS project
mbedtls_repo_name="${mbedtls_repo_name:-mbedtls-mbedtls-2.18.0}"

coverity_path="${coverity_path:-${nfs_volume}/tools/coverity/static-analysis/2019.09}"
#coverity_host="${coverity_host:-coverity.cambridge.arm.com}"
coverity_default_checkers=(
"--all"
"--checker-option DEADCODE:no_dead_default:true"
"--enable AUDIT.SPECULATIVE_EXECUTION_DATA_LEAK"
"--enable ENUM_AS_BOOLEAN"
"--enable-constraint-fpp"
"--ticker-mode none"
"--hfa"
)

#export coverity_host

# Define toolchain version and toolchain binary paths
toolchain_version="9.2-2019.12"

aarch64_none_elf_dir="${nfs_volume}/pdsw/tools/gcc-arm-${toolchain_version}-x86_64-aarch64-none-elf"
aarch64_none_elf_prefix="aarch64-none-elf-"

arm_none_eabi_dir="${nfs_volume}/pdsw/tools/gcc-arm-${toolchain_version}-x86_64-arm-none-eabi"
arm_none_eabi_prefix="arm-none-eabi-"

path_list=(
		"${aarch64_none_elf_dir}/bin"
		"${arm_none_eabi_dir}/bin"
		"${nfs_volume}/pdsw/tools/gcc-arm-none-eabi-5_4-2016q3/bin"
		"$coverity_path/bin"
)

ld_library_path_list=(
)

license_path_list=${license_path_list-(
)}

# Setup various paths
if upon "$retain_paths"; then
	# If explicitly requested, retain local paths; apppend CI paths to the
	# existing ones.
	op="append" extend_path "PATH" "path_list"
	op="append" extend_path "LD_LIBRARY_PATH" "ld_library_path_list"
	op="append" extend_path "LM_LICENSE_FILE" "license_path_list"
else
	# Otherwise, prepend CI paths so that they take effect before local ones
	extend_path "PATH" "path_list"
	extend_path "LD_LIBRARY_PATH" "ld_library_path_list"
	extend_path "LM_LICENSE_FILE" "license_path_list"
fi

export LD_LIBRARY_PATH
export LM_LICENSE_FILE
export ARMLMD_LICENSE_FILE="$LM_LICENSE_FILE"
export ARM_TOOL_VARIANT=ult

# vim: set tw=80 sw=8 noet:
