#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# Enable job control to have background processes run in their own process
# group. That way, we can kill a background process group in one go.
set -m

ci_root="$(readlink -f "$(dirname "$0")/..")"
source "$ci_root/utils.sh"

artefacts="${artefacts-$workspace/artefacts}"

run_root="$workspace/run"
pid_dir="$workspace/pids"

mkdir -p "$pid_dir"
mkdir -p "$run_root"

kill_and_reap() {
	local gid

	# Kill an active process. Ignore errors
	[ "$1" ] || return 0
	kill -0 "$1" &>/dev/null || return 0

	# Kill the group
	gid="$(awk '{print $5}' < /proc/$1/stat)"
	kill -SIGKILL -- "-$gid" &>/dev/null || true
	wait "$gid" &>/dev/null || true
}

# Perform clean up and ignore errors
cleanup() {
	local pid

	# Test success. Kill all background processes so far and wait for them
	pushd "$pid_dir"
	set +e
	while read pid; do
		pid="$(cat $pid)"
		kill_and_reap "$pid"
	done < <(find -name '*.pid')
	popd
}

# Launch a program. Have its PID saved in a file with given name with .pid
# suffix. When the program exits, create a file with .success suffix, or one
# with .fail if it fails. This function blocks, so the caller must '&' this if
# they want to continue. Call must wait for $pid_dir/$name.pid to be created
# should it want to read it.
launch() {
	local pid

	"$@" &
	pid="$!"
	echo "$pid" > "$pid_dir/${name:?}.pid"
	if wait "$pid"; then
		touch "$pid_dir/$name.success"
	else
		touch "$pid_dir/$name.fail"
	fi
}

# Cleanup actions
trap cleanup SIGINT SIGHUP SIGTERM EXIT

# Prevent xterm windows from untracked terminals from popping up, especially
# when running locally
not_upon "$test_run" && export DISPLAY=

# Source variables required for run
source "$artefacts/env"

echo
echo "RUNNING: $TEST_CONFIG"
echo

# Accept BIN_MODE from environment, or default to release. If bin_mode is set
# and non-empty (intended to be set from command line), that takes precedence.
pkg_bin_mode="${BIN_MODE:-release}"
bin_mode="${bin_mode:-$pkg_bin_mode}"

# Assume 0 is the primary UART to track
primary_uart=0

# Assume 4 UARTs by default
num_uarts="${num_uarts:-4}"

# Whether to display primary UART progress live on the console
primary_live="${primary_live-$PRIMARY_LIVE}"

# Change directory so that all binaries can be accessed realtive to where they
# lie
run_cwd="$artefacts/$bin_mode"
cd "$run_cwd"

# Source environment for run
if [ -f "run/env" ]; then
	source "run/env"
fi

# Fail if there was no model path set
if [ -z "$model_path" ]; then
	die "No model path set by package!"
fi

# Launch model with parameters
model_out="$run_root/model_log.txt"
run_sh="$run_root/run.sh"

# Generate run.sh
echo "$model_path \\" > "$run_sh"
sed '/^\s*$/d' < model_params | sort | sed 's/^/\t/;s/$/ \\/' >> "$run_sh"
echo -e "\t\"\$@\"" >> "$run_sh"

echo "Model command line:"
echo
cat "$run_sh"
chmod +x "$run_sh"
echo

# If it's a test run, skip all the hoops and launch model directly.
if upon "$test_run"; then
	"$run_sh" "$@"
	exit 0
fi

# For an automated run, export a known variable so that we can identify stale
# processes spawned by Trusted Firmware CI by inspecting its environment.
export TRUSTED_FIRMWARE_CI="1"

# Change directory to workspace, as all artifacts paths are relative to
# that, and launch the model. Have model use no buffering on stdout
: >"$model_out"
name="model" launch stdbuf -o0 -e0 "$run_sh" &>"$model_out" &
wait_count=0
while :; do
	if [ -f "$pid_dir/model.pid" ]; then
		break
	fi
	sleep 0.1

	let "wait_count += 1"
	if [ "$wait_count" -gt 100 ]; then
		die "Failed to launch model!"
	fi
done
model_pid="$(cat "$pid_dir/model.pid")"

ports_output="$(mktempfile)"
if not_upon "$ports_script"; then
	# Default AWK script to parse model ports
	ports_script="$(mktempfile)"
	cat <<'EOF' >"$ports_script"
/terminal_0/ { ports[0] = $NF }
/terminal_1/ { ports[1] = $NF }
/terminal_2/ { ports[2] = $NF }
/terminal_3/ { ports[3] = $NF }
END {
	for (i = 0; i < num_uarts; i++) {
		if (ports[i] != "")
			print "ports[" i "]=" ports[i]
	}
}
EOF
fi

# Start a watchdog to kill ourselves if we wait too long for the model
# response. Note that this is not the timeout for the whole test, but only for
# the Model to output port numbers.
(
if upon "$jenkins_run"; then
	# Increase this timeout for a cluster run, as it could take longer if
	# the load on the Jenkins server is high.
	model_wait_timeout=120
else
	model_wait_timeout=30
fi
sleep $model_wait_timeout
echo "Model wait timeout!"
kill "$$"
) &
watchdog="$!"

# Parse UARTs ports from early model output. Send a SIGSTOP to the model
# as soon as it outputs all UART ports. This is to prevent the model
# executing before the expect scripts get a chance to connect to the
# UART thereby losing messages.
model_fail=1
while :; do
	awk -v "num_uarts=$num_uarts" -f "$ports_script" "$model_out" \
		> "$ports_output"
	if [ $(wc -l < "$ports_output") -eq "$num_uarts" ]; then
		kill -SIGSTOP "$model_pid"
		model_fail=0
		break
	fi

	# Bail out if model exited meanwhile
	if ! kill -0 "$model_pid" &>/dev/null; then
		echo "Model terminated unexpectedly!"
		break
	fi
done

# Kill the watch dog
kill_and_reap "$watchdog" || true

# Check the model had failed meanwhile, for some reason
if [ "$model_fail" -ne 0 ]; then
	exit 1
fi

# The wait loop above exited after model port numbers have been parsed. The
# script's output is ready to be sourced now.
declare -a ports
source "$ports_output"
rm -f "$ports_output"
if [ "${#ports[@]}" -ne "$num_uarts" ]; then
	echo "Failed to get UART port numbers"
	kill_and_reap "$model_pid"
	unset model_pid
fi

# Launch expect scripts for all UARTs
uarts=0
for u in $(seq 0 $num_uarts | tac); do
	script="run/uart$u/expect"
	if [ -f "$script" ]; then
		script="$(cat "$script")"
	else
		script=
	fi

	# Primary UART must have a script
	if [ -z "$script" ]; then
		if [ "$u" = "$primary_uart" ]; then
			die "No primary UART script!"
		else
			continue
		fi
	fi

	timeout="run/uart$u/timeout"
	if [ -f "$timeout" ]; then
		timeout="$(cat "$timeout")"
	else
		timeout=
	fi
	timeout="${timeout-600}"

	full_log="$run_root/uart${u}_full.txt"

	if [ "$u" = "$primary_uart" ]; then
		star="*"
		uart_name="primary_uart"
	else
		star=" "
		uart_name="uart$u"
	fi

	# Launch expect after exporting required variables
	(
	if [ -f "run/uart$u/env" ]; then
		set -a
		source "run/uart$u/env"
		set +a
	fi

	if [ "$u" = "$primary_uart" ] && upon "$primary_live"; then
		uart_port="${ports[$u]}" timeout="$timeout" \
			name="$uart_name" launch expect -f "$ci_root/expect/$script" | \
				tee "$full_log"
		echo
	else
		uart_port="${ports[$u]}" timeout="$timeout" \
			name="$uart_name" launch expect -f "$ci_root/expect/$script" \
				&>"$full_log"
	fi

	) &

	let "uarts += 1"
	echo "Tracking UART$u$star with $script; timeout $timeout."
done

# Wait here long 'enough' for expect scripts to connect to ports; then
# let the model proceed
sleep 2
kill -SIGCONT "$model_pid"

# Wait for all children. Note that the wait below is *not* a timed wait.
result=0

set +e
pushd "$pid_dir"
while :; do
	wait -n

	# Exit failure if we've any failures
	if [ "$(wc -l < <(find -name '*.fail'))" -ne 0 ]; then
		result=1
		break
	fi

	# We're done if the primary UART exits success
	if [ -f "$pid_dir/primary_uart.success" ]; then
		break
	fi
done
popd

cleanup

if [ "$result" -eq 0 ]; then
	echo "Test success!"
else
	echo "Test failed!"
fi

if upon "$jenkins_run"; then
	echo
	echo "Artefacts location: $BUILD_URL."
	echo
fi

if upon "$jenkins_run" && upon "$artefacts_receiver" && [ -d "$workspace/run" ]; then
	pushd "$workspace"
	run_archive="run.tar.xz"
	tar -cJf "$run_archive" "run"
	where="$artefacts_receiver/${TEST_GROUP:?}/${TEST_CONFIG:?}/$run_archive"
	where+="?j=$JOB_NAME&b=$BUILD_NUMBER"
	if wget -q --method=PUT --body-file="$run_archive" "$where"; then
		echo "Run logs submitted to $where."
	else
		echo "Error submitting run logs to $where."
	fi
	popd
fi

exit "$result"

# vim: set tw=80 sw=8 noet:
