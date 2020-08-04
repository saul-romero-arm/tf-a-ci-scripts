#!/usr/bin/env python3

"""
Script to automate the manual juno tests that used to require the Juno board
to be manually power cycled.

"""

import argparse
import datetime
import enum
import logging
import os
import pexpect
import re
import shutil
import sys
import time
import zipfile
from pexpect import pxssh

################################################################################
# Classes                                                                      #
################################################################################

class CriticalError(Exception):
    """
    Raised when a serious issue occurs that will likely mean abort.
    """
    pass

class TestStatus(enum.Enum):
    """
    This is an enum to describe possible return values from test handlers.
    """
    SUCCESS = 0
    FAILURE = 1
    CONTINUE = 2

class JunoBoardManager(object):
    """
    Manage Juno board reservation and mounts with support for context
    management.
    Parameters
      ssh (pxssh object): SSH connection to remote machine
      password (string): sudo password for mounting/unmounting
    """

    def __init__(self, ssh, password):
        self.ssh = ssh
        self.path = ""
        self.password = password
        self.mounted = False

    def reserve(self):
        """
        Try to reserve a Juno board.
        """
        for path in ["/home/login/generaljuno1", "/home/login/generaljuno2"]:
            logging.info("Trying %s...", path)
            self.ssh.before = ""
            self.ssh.sendline("%s/reserve.sh" % path)
            res = self.ssh.expect(["RESERVE_SCRIPT_SUCCESS", "RESERVE_SCRIPT_FAIL", pexpect.EOF, \
                pexpect.TIMEOUT], timeout=10)
            if res == 0:
                self.path = path
                return
            if res == 1:
                continue
            else:
                logging.error(self.ssh.before.decode("utf-8"))
                raise CriticalError("Unexpected pexpect result: %d" % res)
        raise CriticalError("Could not reserve a Juno board.")

    def release(self):
        """
        Release a previously reserved Juno board.
        """
        if self.mounted:
            self.unmount()
            logging.info("Unmounted Juno storage device.")
        if self.path == "":
            raise CriticalError("No Juno board reserved.")
        self.ssh.before = ""
        self.ssh.sendline("%s/release.sh" % self.path)
        res = self.ssh.expect(["RELEASE_SCRIPT_SUCCESS", "RELEASE_SCRIPT_FAIL", pexpect.EOF, \
            pexpect.TIMEOUT], timeout=10)
        if res == 0:
            return
        logging.error(self.ssh.before.decode("utf-8"))
        raise CriticalError("Unexpected pexpect result: %d" % res)

    def mount(self):
        """
        Mount the reserved Juno board storage device.
        """
        if self.path == "":
            raise CriticalError("No Juno board reserved.")
        if self.mounted:
            return
        self.ssh.before = ""
        self.ssh.sendline("%s/mount.sh" % self.path)
        res = self.ssh.expect(["password for", "MOUNT_SCRIPT_SUCCESS", pexpect.TIMEOUT, \
            pexpect.EOF, "MOUNT_SCRIPT_FAIL"], timeout=10)
        if res == 0:
            self.ssh.before = ""
            self.ssh.sendline("%s" % self.password)
            res = self.ssh.expect(["MOUNT_SCRIPT_SUCCESS", "Sorry, try again.", pexpect.TIMEOUT, \
                pexpect.EOF, "MOUNT_SCRIPT_FAIL"], timeout=10)
            if res == 0:
                self.mounted = True
                return
            elif res == 1:
                raise CriticalError("Incorrect sudo password.")
            logging.error(self.ssh.before.decode("utf-8"))
            raise CriticalError("Unexpected pexpect result: %d" % res)
        elif res == 1:
            self.mounted = True
            return
        logging.error(self.ssh.before.decode("utf-8"))
        raise CriticalError("Unexpected pexpect result: %d" % res)

    def unmount(self):
        """
        Unmount the reserved Juno board storage device.
        """
        if self.path == "":
            raise CriticalError("No Juno board reserved.")
        if not self.mounted:
            return
        self.ssh.before = ""
        self.ssh.sendline("%s/unmount.sh" % self.path)
        # long timeout here since linux likes to queue file IO operations
        res = self.ssh.expect(["password for", "UNMOUNT_SCRIPT_SUCCESS", pexpect.TIMEOUT, \
            pexpect.EOF, "UNMOUNT_SCRIPT_FAIL"], timeout=600)
        if res == 0:
            self.ssh.before = ""
            self.ssh.sendline("%s" % self.password)
            res = self.ssh.expect(["UNMOUNT_SCRIPT_SUCCESS", "Sorry, try again.", pexpect.TIMEOUT, \
                pexpect.EOF, "UNMOUNT_SCRIPT_FAIL"], timeout=600)
            if res == 0:
                self.mounted = False
                return
            elif res == 1:
                raise CriticalError("Incorrect sudo password.")
            logging.error(self.ssh.before.decode("utf-8"))
            raise CriticalError("Unexpected pexpect result: %d" % res)
        elif res == 1:
            self.mounted = False
            return
        elif res == 2:
            raise CriticalError("Timed out waiting for unmount.")
        logging.error(self.ssh.before.decode("utf-8"))
        raise CriticalError("Unexpected pexpect result: %d" % res)

    def get_path(self):
        """
        Get the path to the reserved Juno board.
        """
        if self.path == "":
            raise CriticalError("No Juno board reserved.")
        return self.path

    def __enter__(self):
        # Attempt to reserve if it hasn't been done already
        if self.path == "":
            self.reserve()

    def __exit__(self, exc_type, exc_value, exc_traceback):
        self.release()

################################################################################
# Helper Functions                                                             #
################################################################################

def recover_juno(ssh, juno_board, uart):
    """
    If mount fails, this function attempts to power cycle the juno board, cancel
    auto-boot, and manually enable debug USB before any potentially bad code
    can run.
    Parameters
      ssh (pxssh object): ssh connection to remote machine
      juno_board (JunoBoardManager): Juno instance to attempt to recover
      uart (pexpect): Connection to juno uart
    """
    power_off(ssh, juno_board.get_path())
    time.sleep(10)
    power_on(ssh, juno_board.get_path())
    # Wait for auto boot message thens end an enter press
    res = uart.expect(["Press Enter to stop auto boot", pexpect.EOF, pexpect.TIMEOUT], timeout=60)
    if res != 0:
        raise CriticalError("Juno auto boot prompt not detected, recovery failed.")
    uart.sendline("")
    # Wait for MCC command prompt then send "usb_on"
    res = uart.expect(["Cmd>", pexpect.EOF, pexpect.TIMEOUT], timeout=10)
    if res != 0:
        raise CriticalError("Juno MCC prompt not detected, recovery failed.")
    uart.sendline("usb_on")
    # Wait for debug usb confirmation
    res = uart.expect(["Enabling debug USB...", pexpect.EOF, pexpect.TIMEOUT], timeout=10)
    if res != 0:
        raise CriticalError("Debug usb not enabled, recovery failed.")
    # Dead wait for linux to detect the USB device then try to mount again
    time.sleep(10)
    juno_board.mount()

def copy_file_to_remote(source, dest, remote, user, password):
    """
    Uses SCP to copy a file to a remote machine.
    Parameters
      source (string): Source path
      dest (string): Destination path
      remote (string): Name or IP address of remote machine
      user (string): Username to login with
      password (string): Password to login/sudo with
    """
    scp = "scp -r %s %s@%s:%s" % (source, user, remote, dest)
    copy = pexpect.spawn(scp)
    copy.expect("password:")
    copy.sendline(password)
    res = copy.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=600)
    if res == 0:
        copy.close()
        if copy.exitstatus == 0:
            return
        raise CriticalError("Unexpected error occurred during SCP: %d" % copy.exitstatus)
    elif res == 1:
        raise CriticalError("SCP operation timed out.")
    raise CriticalError("Unexpected pexpect result: %d" % res)

def extract_zip_file(source, dest):
    """
    Extracts a zip file on the local machine.
    Parameters
      source (string): Path to input zip file
      dest (string): Path to output directory
    """
    try:
        with zipfile.ZipFile(source, 'r') as src:
            src.extractall(dest)
        return
    except Exception:
        raise CriticalError("Could not extract boardfiles.")

def remote_copy(ssh, source, dest):
    """
    Copy files from remote workspace to Juno directory using rsync
    Parameters
      ssh (pxssh object): Connection to remote system
      source (string): Source file path
      dest (string): Destination file path
    """
    ssh.before = ""
    ssh.sendline("rsync -rt %s %s" % (source, dest))
    res = ssh.expect(["$", pexpect.EOF, pexpect.TIMEOUT], timeout=60)
    if res != 0:
        logging.error(ssh.before.decode("utf-8"))
        raise CriticalError("Unexpected error occurred during rsync operation.")
    ssh.before = ""
    ssh.sendline("echo $?")
    res = ssh.expect(["0", pexpect.EOF, pexpect.TIMEOUT], timeout=10)
    if res != 0:
        logging.error(ssh.before.decode("utf-8"))
        raise CriticalError("rsync failed")
    return

def connect_juno_uart(host, port):
    """
    Spawn a pexpect object for the Juno UART
    Parameters
      host (string): Telnet host name or IP addres
      port (int): Telnet port number
    Returns
        pexpect object if successful
    """
    uart = pexpect.spawn("telnet %s %d" % (host, port))
    result = uart.expect(["Escape character is", pexpect.EOF, pexpect.TIMEOUT], timeout=10)
    if result == 0:
        return uart
    raise CriticalError("Could not connect to Juno UART.")

def get_uart_port(ssh, juno):
    """
    Get the telnet port for the Juno UART
    Parameters
      ssh (pxssh object): SSH session to remote machine
    Returns
      int: Telnet port number
    """
    ssh.before = ""
    ssh.sendline("cat %s/telnetport" % juno)
    res = ssh.expect([pexpect.TIMEOUT], timeout=1)
    if res == 0:
        match = re.search(r"port: (\d+)", ssh.before.decode("utf-8"))
        if match:
            return int(match.group(1))
    raise CriticalError("Could not get telnet port.")

def power_off(ssh, juno):
    """
    Power off the Juno board
    Parameters
      ssh (pxssh object): SSH session to remote machine
      juno (string): Path to Juno directory on remote
    """
    ssh.before = ""
    ssh.sendline("%s/poweroff.sh" % juno)
    res = ssh.expect(["POWEROFF_SCRIPT_SUCCESS", pexpect.EOF, pexpect.TIMEOUT, \
        "POWEROFF_SCRIPT_FAIL"], timeout=10)
    if res == 0:
        return
    logging.error(ssh.before.decode("utf-8"))
    raise CriticalError("Could not power off the Juno board.")

def power_on(ssh, juno):
    """
    Power on the Juno board
    Parameters
      ssh (pxssh object): SSH session to remote machine
      juno (string): Path to Juno directory on remote
    """
    ssh.before = ""
    ssh.sendline("%s/poweron.sh" % juno)
    res = ssh.expect(["POWERON_SCRIPT_SUCCESS", pexpect.EOF, pexpect.TIMEOUT, \
        "POWERON_SCRIPT_FAIL"], timeout=10)
    if res == 0:
        return
    logging.error(ssh.before.decode("utf-8"))
    raise CriticalError("Could not power on the Juno board.")

def erase_juno(ssh, juno):
    """
    Erase the mounted Juno storage device
    Parameters
      ssh (pxssh object): SSH session to remote machine
      juno (string): Path to Juno directory on remote
    """
    ssh.before = ""
    ssh.sendline("%s/erasejuno.sh" % juno)
    res = ssh.expect(["ERASEJUNO_SCRIPT_SUCCESS", "ERASEJUNO_SCRIPT_FAIL", pexpect.EOF, \
        pexpect.TIMEOUT], timeout=30)
    if res == 0:
        return
    logging.error(ssh.before.decode("utf-8"))
    raise CriticalError("Could not erase the Juno storage device.")

def erase_juno_workspace(ssh, juno):
    """
    Erase the Juno workspace
    Parameters
      ssh (pxssh object): SSH session to remote machine
      juno (string): Path to Juno directory on remote
    """
    ssh.before = ""
    ssh.sendline("%s/eraseworkspace.sh" % juno)
    res = ssh.expect(["ERASEWORKSPACE_SCRIPT_SUCCESS", "ERASEWORKSPACE_SCRIPT_FAIL", pexpect.EOF, \
        pexpect.TIMEOUT], timeout=30)
    if res == 0:
        return
    logging.error(ssh.before.decode("utf-8"))
    raise CriticalError("Could not erase the remote workspace.")

def process_uart_output(uart, timeout, handler, telnethost, telnetport):
    """
    This function receives UART data from the Juno board, creates a full line
    of text, then passes it to a test handler function.
    Parameters
      uart (pexpect): Pexpect process containing UART telnet session
      timeout (int): How long to wait for test completion.
      handler (function): Function to pass each line of test output to.
      telnethost (string): Telnet host to use if uart connection fails.
      telnetport (int): Telnet port to use if uart connection fails.
    """
    # Start timeout counter
    timeout_start = datetime.datetime.now()

    line = ""
    while True:
        try:
            # Check if timeout has expired
            elapsed = datetime.datetime.now() - timeout_start
            if elapsed.total_seconds() > timeout:
                raise CriticalError("Test timed out, see log file.")

            # Read next character from Juno
            char = uart.read_nonblocking(size=1, timeout=1).decode("utf-8")
            if '\n' in char:
                logging.info("JUNO: %s", line)

                result = handler(uart, line)
                if result == TestStatus.SUCCESS:
                    return
                elif result == TestStatus.FAILURE:
                    raise CriticalError("Test manager returned TestStatus.FAILURE")

                line = ""
            else:
                line = line + char

        # uart.read_nonblocking will throw timeouts a lot by design so catch and ignore
        except pexpect.TIMEOUT:
            continue
        except pexpect.EOF:
            logging.warning("Connection lost unexpectedly, attempting to restart.")
            try:
                uart = connect_juno_uart(telnethost, telnetport)
            except CriticalError:
                raise CriticalError("Could not reopen Juno UART")
            continue
        except OSError:
            raise CriticalError("Unexpected OSError occurred.")
        except UnicodeDecodeError:
            continue
        except Exception as e:
            # This case exists to catch any weird or rare exceptions.
            raise CriticalError("Unexpected exception occurred: %s" % str(e))

################################################################################
# Test Handlers                                                                #
################################################################################

TEST_CASE_TFTF_MANUAL_PASS_COUNT = 0
TEST_CASE_TFTF_MANUAL_CRASH_COUNT = 0
TEST_CASE_TFTF_MANUAL_FAIL_COUNT = 0
def test_case_tftf_manual(uart, line):
    """
    This function handles TFTF tests and parses the output into a pass or fail
    result.  Any crashes or fails result in an overall test failure but skips
    and passes are fine.
    """
    global TEST_CASE_TFTF_MANUAL_PASS_COUNT
    global TEST_CASE_TFTF_MANUAL_CRASH_COUNT
    global TEST_CASE_TFTF_MANUAL_FAIL_COUNT

    # This test needs to be powered back on a few times
    if "Board powered down, use REBOOT to restart." in line:
        # time delay to let things finish up
        time.sleep(3)
        uart.sendline("reboot")
        return TestStatus.CONTINUE

    elif "Tests Passed" in line:
        match = re.search(r"Tests Passed  : (\d+)", line)
        if match:
            TEST_CASE_TFTF_MANUAL_PASS_COUNT = int(match.group(1))
            return TestStatus.CONTINUE
        logging.error(r"Error parsing line: %s", line)
        return TestStatus.FAILURE

    elif "Tests Failed" in line:
        match = re.search(r"Tests Failed  : (\d+)", line)
        if match:
            TEST_CASE_TFTF_MANUAL_FAIL_COUNT = int(match.group(1))
            return TestStatus.CONTINUE
        logging.error("Error parsing line: %s", line)
        return TestStatus.FAILURE

    elif "Tests Crashed" in line:
        match = re.search(r"Tests Crashed : (\d+)", line)
        if match:
            TEST_CASE_TFTF_MANUAL_CRASH_COUNT = int(match.group(1))
            return TestStatus.CONTINUE
        logging.error("Error parsing line: %s", line)
        return TestStatus.FAILURE

    elif "Total tests" in line:
        if TEST_CASE_TFTF_MANUAL_PASS_COUNT == 0:
            return TestStatus.FAILURE
        if TEST_CASE_TFTF_MANUAL_CRASH_COUNT > 0:
            return TestStatus.FAILURE
        if TEST_CASE_TFTF_MANUAL_FAIL_COUNT > 0:
            return TestStatus.FAILURE
        return TestStatus.SUCCESS

    return TestStatus.CONTINUE

TEST_CASE_LINUX_MANUAL_SHUTDOWN_HALT_SENT = False
def test_case_linux_manual_shutdown(uart, line):
    """
    This handler performs a linux manual shutdown test by waiting for the linux
    prompt and sending the appropriate halt command, then waiting for the
    expected output.
    """
    global TEST_CASE_LINUX_MANUAL_SHUTDOWN_HALT_SENT

    # Look for Linux prompt
    if "/ #" in line and TEST_CASE_LINUX_MANUAL_SHUTDOWN_HALT_SENT is False:
        time.sleep(3)
        uart.sendline("halt -f")
        TEST_CASE_LINUX_MANUAL_SHUTDOWN_HALT_SENT = True
        return TestStatus.CONTINUE

    # Once halt command has been issued, wait for confirmation
    elif "reboot: System halted" in line:
        return TestStatus.SUCCESS

    # For any other result, continue.
    return TestStatus.CONTINUE

################################################################################
# Script Main                                                                  #
################################################################################

def main():
    """
    Main function, handles the initial set up and test dispatch to Juno board.
    """
    parser = argparse.ArgumentParser(description="Launch a Juno manual test.")
    parser.add_argument("host", type=str, help="Name or IP address of Juno host system.")
    parser.add_argument("username", type=str, help="Username to login to host system.")
    parser.add_argument("password", type=str, help="Password to login to host system.")
    parser.add_argument("boardfiles", type=str, help="ZIP file containing Juno boardfiles.")
    parser.add_argument("workspace", type=str, help="Directory for scratch files.")
    parser.add_argument("testname", type=str, help="Name of test to run.")
    parser.add_argument("timeout", type=int, help="Time to wait for test completion.")
    parser.add_argument("logfile", type=str, help="Path to log file to create.")
    parser.add_argument("-l", "--list", action='store_true', help="List supported test cases.")
    args = parser.parse_args()

    # Print list if requested
    if args.list:
        print("Supported Tests")
        print("  tftf-manual-generic - Should work for all TFTF tests.")
        print("  linux-manual-shutdown - Waits for Linux prompt and sends halt command.")
        exit(0)

    # Start logging
    print("Creating log file: %s" % args.logfile)
    logging.basicConfig(filename=args.logfile, level=logging.DEBUG, \
        format="[%(asctime)s] %(message)s", datefmt="%I:%M:%S")
    logging.getLogger().addHandler(logging.StreamHandler(sys.stdout))

    # Make sure test name is supported so we don't waste time if it isn't.
    if args.testname == "tftf-manual-generic":
        test_handler = test_case_tftf_manual
    elif args.testname == "linux-manual-shutdown":
        test_handler = test_case_linux_manual_shutdown
    else:
        logging.error("Test name \"%s\" invalid or not supported.", args.testname)
        exit(1)
    logging.info("Selected test \"%s\"", args.testname)

    # Helper functions either succeed or raise CriticalError so no error checking is done here
    try:
        # Start SSH session to host machine
        logging.info("Starting SSH session to remote machine.")
        ssh = pxssh.pxssh()
        if not ssh.login(args.host, args.username, args.password):
            raise CriticalError("Could not start SSH session.")
        # Disable character echo
        ssh.sendline("stty -echo")
        with ssh:

            # Try to reserve a juno board
            juno_board = JunoBoardManager(ssh, args.password)
            juno_board.reserve()
            juno = juno_board.get_path()
            logging.info("Reserved %s", juno)
            with juno_board:

                # Get UART port and start telnet session
                logging.info("Opening Juno UART")
                port = get_uart_port(ssh, juno)
                logging.info("Using telnet port %d", port)
                uart = connect_juno_uart(args.host, port)
                with uart:

                    # Extract boardfiles locally
                    logging.info("Extracting boardfiles.")
                    local_boardfiles = os.path.join(args.workspace, "boardfiles")
                    if os.path.exists(local_boardfiles):
                        shutil.rmtree(local_boardfiles)
                    os.mkdir(local_boardfiles)
                    extract_zip_file(args.boardfiles, local_boardfiles)

                    # Clear out the workspace directory on the remote system
                    logging.info("Erasing remote workspace.")
                    erase_juno_workspace(ssh, juno)

                    # SCP boardfiles to juno host
                    logging.info("Copying boardfiles to remote system.")
                    copy_file_to_remote(os.path.join(local_boardfiles), \
                        os.path.join(juno, "workspace"), args.host, args.username, args.password)

                    # Try to mount the storage device
                    logging.info("Mounting the Juno storage device.")
                    try:
                        juno_board.mount()
                    except CriticalError:
                        logging.info("Mount failed, attempting to recover Juno board.")
                        recover_juno(ssh, juno_board, uart)
                        logging.info("Juno board recovered.")

                    # Move boardfiles from temp directory to juno storage
                    logging.info("Copying new boardfiles to storage device.")
                    remote_copy(ssh, os.path.join(juno, "workspace", "boardfiles", "*"), \
                        os.path.join(juno, "juno"))

                    # Unmounting the juno board.
                    logging.info("Unmounting Juno storage device and finishing pending I/O.")
                    juno_board.unmount()

                    # Power cycle the juno board to reboot it. */
                    logging.info("Rebooting the Juno board.")
                    power_off(ssh, juno)
                    # dead wait to let the power supply do its thing
                    time.sleep(10)
                    power_on(ssh, juno)

                    # dead wait to let the power supply do its thing
                    time.sleep(10)

                    # Process UART output and wait for test completion
                    process_uart_output(uart, args.timeout, test_handler, args.host, port)
                    logging.info("Tests Passed!")

    except CriticalError as exception:
        logging.error(str(exception))
        exit(1)

    # Exit with 0 on successful finish
    exit(0)

################################################################################
# Script Entry Point                                                           #
################################################################################

if __name__ == "__main__":
    main()
