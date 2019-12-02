#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# This file is sourced from the build_package.sh script to use
# coverity_wrapper() function as a build wrapper.
#
# This wrapper supports two work flows:
#
#  - Compare the branch under test with that of master, and print defects. If
#    there are defects, we arrange the build to be marked as unstable. Set
#    $cov_run_type to 'branch-report-compare' to use this.
#
#  - Commit and create snapshot for the entire branch. Set $cov_run_type to
#    'branch-report-full' to use this.
#
# Coverity analysis involves contacting the server, which have shown to be very
# slow. Depending on the type of analysis performed, we might have to do
# analysis more than once, and doing that in series would only increase the turn
# around time. To mitigate this, all Coverity commands are saved as small
# snippets, and are then called from a Makefile. Make take care of running
# commands in parallel (all this at the expense of readability).

coverity_wrapper() {
	local cov_dir="$workspace/coverity"
	local cov_config="$cov_dir/config"
	local cov_compiler="${cov_compiler:-${CROSS_COMPILE}gcc}"

	local golden_repo="$cov_dir/golden-repo"
	local golden_snapshot="$cov_dir/golden-snapshot"

	local branch_repo="$cov_dir/branch-repo"
	local branch_snapshot="$cov_dir/branch-snapshot"

	local auth_file="${cov_auth_file:-$ci_root/coverity/tfcibot@$coverity_host}"
	local makefile="$workspace/makefile.cov"
	local snippets_dir="$cov_dir/snippets"
	local stream_name="${BUILD_CONFIG:?}"

	local ref_arg
	local description
	local need_compare

	echo_w
	mkdir -p "$cov_dir"

	if echo "${cov_run_type:?}" | grep -iq "branch-report-compare"; then
		need_compare=1
		local golden_url="${cov_golden_url:-$tf_src_repo_url}"
		local golden_ref="${cov_golden_ref:-master}"
	fi

	if upon "$local_ci"; then
		description="$USER-local ${cov_checker:?}"
		# Reference repository can't be shallow
		if [ ! -f "$tf_root/.git/shallow" ]; then
			ref_arg="--reference $tf_root"
		fi
	else
		description="$JOB_NAME#$BUILD_NUMBER ${cov_checker:?}"
		ref_arg="--reference $project_filer/ref-repos/trusted-firmware"
	fi

	# Create a stream and assign to Trusted Firmware project
	chmod 400 "$auth_file"

	mkdir -p "$snippets_dir"
	cat <<EOF >"$makefile"
SHELL := /bin/bash

define run-snippet
echo ":\$@" >&3
echo ">\$@: \$\$(date)"
if ! bash -ex $snippets_dir/\$@; then \\
	echo "  :\$@ failed! See build log" >&3; \\
	exit 1; \\
fi
echo "<\$@: \$\$(date)"
endef

EOF

	create_snippet() {
		# Create a script snippet
		cat >"$snippets_dir/${name?}"

		# Add a rule to the makefile
		cat <<EOF >>"$makefile"
$name:${deps:+ $deps}
	@\$(run-snippet)

EOF
	}

	# golden-setup. Additionally query for a snapshot ID corresponding to
	# this version in the stream. If a snapshot ID exists, the comparison
	# file is generated containing the snapshot ID.
	#
	# We need to make a shallow clone of the repository first in order to
	# get the reference, however. And, if later we find needing a fresh
	# snapshot, we unshallow that.
	cat <<EOF | name="golden-setup" create_snippet
git clone --depth 1 -q $ref_arg "$golden_url" "$golden_repo"
cd -P "$golden_repo"
git fetch --depth 1 -q origin "$golden_ref"
git checkout -q FETCH_HEAD

if [ -z "$cov_force_commit" ]; then
	"$ci_root/script/get_latest_snapshot.py" \\
		--host "$coverity_host" \\
		--file "$golden_snapshot" \\
		--description "*$cov_checker*" \\
		--version "\$(git show -q --format=%H)" \\
		"$stream_name" 2>&3 || true
fi

{
echo "  golden: $golden_url $golden_ref"
echo "  golden: \$(git show -q --format=%H)"
} >&3

if [ -f "$golden_snapshot" ]; then
	echo "  golden: snapshot ID \$(cat $golden_snapshot) exists" >&3
else
	git fetch -q --unshallow origin
fi
EOF


	# Setup branch
	if upon "$local_ci"; then
		if not_upon "$need_compare"; then
			ln -s "$tf_root" "$branch_repo"

			# Run scanning as-is since we don't need a comparison.
			cat <<EOF | name="branch-setup" create_snippet
if [ "$dont_clean" != 1 ]; then
	cd -P "$branch_repo"
	MAKEFLAGS= make distclean
fi
EOF
		else
			# Running comparison means that we need to make a merge
			# commit. It's undesirable to do that on the user's
			# working copy, so do it on a separate one.
			cat <<EOF | name="branch-setup" create_snippet
git clone -q $ref_arg "$tf_src_repo_url" "$branch_repo"
cd -P "$branch_repo"
git checkout -b cov-branch origin/master
rsync -a --exclude=".git" --exclude "**.o" --exclude "**.d" "$tf_root/" .
git add .
git -c user.useconfigonly=false commit --allow-empty -q -m "Test branch"
git checkout master
git -c user.useconfigonly=false merge --no-ff -q cov-branch

git remote add golden "$golden_url"
git fetch -q golden "$golden_ref"
git checkout -q -b cov-golden FETCH_HEAD
git -c user.useconfigonly=false merge --no-edit --no-ff -q cov-branch
EOF
		fi
	else
		# Use the local checkout at $tf_root for analysing branch and
		# golden together
		ln -s "$tf_root" "$branch_repo"

		cat <<EOF | name="branch-setup" create_snippet
if [ "$need_compare" ]; then
	cd -P "$branch_repo"
	if [ -f ".git/shallow" ]; then
		git fetch -q --unshallow origin
	fi
	git remote add golden "$golden_url"
	git fetch -q golden $golden_ref
	git branch cov-branch HEAD
	git checkout -q -b cov-golden FETCH_HEAD
	echo "  branch: \$(git show -q --format=%H cov-branch)" >&3
	git -c user.useconfigonly=false merge --no-edit --no-ff -q cov-branch
fi
EOF
	fi


	# Setup stream
	cat <<EOF | name="stream-setup" create_snippet
if cov-manage-im --mode streams --add --set "name:$stream_name" \\
		--auth-key-file "$auth_file" \\
		--host "$coverity_host"; then
	cov-manage-im --mode projects --name "Arm Trusted Firmware" --update \\
		--insert "stream:$stream_name" --auth-key-file "$auth_file" \\
		--host "$coverity_host"
fi
EOF


	# Coverity configuration
	cat <<EOF | name="cov-config" create_snippet
cov-configure --comptype gcc --template --compiler "$cov_compiler" \\
	--config "$cov_config/config.xml"
EOF


	# cov-build on golden; only performed if a comparison file doesn't
	# exist.
	cat <<EOF | name="golden-cov-build" deps="cov-config golden-setup" \
		create_snippet
if [ ! -f "$golden_snapshot" -o -n "$cov_force_commit" ]; then
	cd -P "$golden_repo"
	MAKEFLAGS= cov-build --config "$cov_config/config.xml" \\
		--dir "$cov_dir/golden" $@
else
	echo "  golden: cov-build skipped" >&3
fi
EOF


	# cov-analyze on golden; only performed if a comparison file doesn't
	# exist.
	cat <<EOF | name="golden-cov-analyze" deps="golden-cov-build" \
		create_snippet
if [ ! -f "$golden_snapshot" -o -n "$cov_force_commit" ]; then
	cd -P "$golden_repo"
	cov-analyze --dir "$cov_dir/golden" $cov_options --verbose 0 \\
		--strip-path "\$(pwd -P)" \\
		--redirect "stdout,$cov_dir/golden.txt"
else
	echo "  golden: cov-analyze skipped" >&3
fi
EOF


	# cov-commit-defects on golden. Since more than one job could have
	# started analyzing golden after finding the snapshot misssing, we check
	# for a snapshot again, and a commit only performed if a comparison file
	# doesn't exist.
	cat <<EOF | name="golden-cov-commit-defects" \
		deps="stream-setup golden-cov-analyze" create_snippet
if [ ! -f "$golden_snapshot" -a -z "$cov_force_commit" ]; then
	"$ci_root/script/get_latest_snapshot.py" \\
		--host "$coverity_host" \\
		--file "$golden_snapshot" \\
		--description "*$cov_checker*" \\
		--version "\$(git show -q --format=%H)" \\
		"$stream_name" 2>&3 || true
	retried=1
fi

if [ ! -f "$golden_snapshot" -o -n "$cov_force_commit" ]; then
	cd -P "$golden_repo"
	cov-commit-defects --dir "$cov_dir/golden" --host "$coverity_host" \\
		--stream "$stream_name" --auth-key-file "$auth_file" \\
		--version "\$(git show -q --format=%H)" \\
		 --description "$description" \\
		--snapshot-id-file "$golden_snapshot"
	echo "  golden: new snapshot ID: \$(cat $golden_snapshot)" >&3
elif [ "\$retried" ]; then
	{
	echo "  golden: snapshot ID \$(cat $golden_snapshot) now exists"
	echo "  golden: cov-commit-defects skipped"
	} >&3
else
	echo "  golden: cov-commit-defects skipped" >&3
fi
EOF


	# cov-build on branch
	cat <<EOF | name="branch-cov-build" deps="cov-config branch-setup" \
		create_snippet
cd -P "$branch_repo"
MAKEFLAGS= cov-build --config "$cov_config/config.xml" --dir "$cov_dir/branch" $@
EOF


	# cov-analyze on branch
	cat <<EOF | name="branch-cov-analyze" deps="branch-cov-build" \
		create_snippet
cd -P "$branch_repo"
cov-analyze --dir "$cov_dir/branch" $cov_options --verbose 0 \\
	--strip-path "\$(pwd -P)" \\
	--redirect "stdout,$cov_dir/branch.txt"
EOF


	# cov-commit-defects on branch
	cat <<EOF | name="branch-cov-commit-defects" \
		deps="stream-setup branch-cov-analyze" create_snippet
if [ "$cov_force_commit" ]; then
	cd -P "$branch_repo"
	cov-commit-defects --dir "$cov_dir/branch" --host "$coverity_host" \\
		--stream "$stream_name" --description "$description" \\
		--version "\$(git show -q --format=%H%)" \\
		--auth-key-file "$auth_file" \\
		--snapshot-id-file "$branch_snapshot"
	echo "  branch: new snapshot ID: \$(cat $branch_snapshot)" >&3
else
	echo "  branch: cov-commit-defects skipped" >&3
fi
EOF


	# cov-commit-defects on branch, but compare with golden
	cat <<EOF | name="branch-report-compare" \
		deps="golden-cov-commit-defects branch-cov-analyze" create_snippet
cov-commit-defects --dir "$cov_dir/branch" --host "$coverity_host" \\
	--stream "$stream_name" --auth-key-file "$auth_file" \\
	--preview-report-v2 "$cov_dir/report.json" \\
	--comparison-snapshot-id "\$(cat $golden_snapshot)"
EOF


	# cov-commit-defects on branch to report branch report
	cat <<EOF | name="branch-report-full" \
		deps="branch-cov-commit-defects stream-setup branch-cov-analyze" \
		create_snippet
cov-commit-defects --dir "$cov_dir/branch" --host "$coverity_host" \\
	--stream "$stream_name" --auth-key-file "$auth_file" \\
	--preview-report-v2 "$cov_dir/report.json"
EOF

	local minus_j="-j"
	if upon "$cov_serial_build"; then
		minus_j=
	fi

	# Call Coverity targets
	echo "Coverity run type: ${cov_run_type:?}"
	if ! eval MAKEFLAGS= make -r $minus_j -f "$makefile" $cov_run_type; then
		return 1
	fi

	# Generate a text report
	local defects_file="$workspace/coverity_report.txt"

	if [ -f "$cov_dir/report.json" ]; then
		python3 "$ci_root/script/coverity_parser.py" \
				--output "$workspace/defects.json" \
				$cov_report_options \
				"$cov_dir/report.json" >"$defects_file" 2>&3 || true
	fi

	# If there were defects, print them out to the console. For local CI,
	# print them in yellow--the same color we'd use for UNSTABLE builds.
	if [ -s "$defects_file" ]; then
		echo_w
		echo_w "Coverity defects found:"
		echo_w
		if upon "$local_ci"; then
			echo_w "$(tput setaf 3)"
		fi
		cat "$defects_file" >&3
		if upon "$local_ci"; then
			echo_w "$(tput sgr0)"
		fi
		echo_w
		echo_w "$(wc -l < "$defects_file") defects reported."
		echo_w
		build_unstable >&3
		echo_w
	else
		echo_w
		echo_w "No coverity defects found."
		echo_w
	fi
}
