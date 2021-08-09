#!/usr/bin/env python3
#
# Copyright (c) 2019-2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import argparse
import os
import subprocess
import sys
import logging
import tempfile
import yaml


def case_infra_error(case):
    try:
        if case["metadata"]["error_type"] == "Infrastructure":
            logging.error("case %s: infra error is type Infrastructure", case["id"])
            return False
        elif "timed out" in case["metadata"]["error_msg"]:
            logging.error(
                "case %s: infra error: %s", case["id"], case["metadata"]["error_msg"]
            )
            return False
        else:
            return True
    except KeyError:
        return True


def not_infra_error(path):
    """Returns a boolean indicating if there was not an infra error"""
    try:
        with open(path) as file:
            results = yaml.safe_load(file)
        return all(case_infra_error(tc) for tc in results)
    except FileNotFoundError:
        logging.warning("Could not open results file %s", path)
        return True


def run_one_job(cmd):
    """Run a job and return a boolean indicating if there was not an infra error.
    Raises a `subprocess.CalledProcessError` when the called script fails.
    """
    subprocess.run(cmd, check=True)
    return not_infra_error("job_results.yaml")


def retry_job(cmd, retries):
    """Run a job until there was not an infra error or retries are exhausted.
    Raises a `subprocess.CalledProcessError` when the called script fails.
    """
    logging.debug("trying job %s up to %d times", str(cmd), retries)
    return any(run_one_job(cmd) for _ in range(retries))


if __name__ == "__main__":

    # To deploy and boot the artefacts on a board in LAVA a platform specific
    # yaml file should be dispatched to LAVA. The below logic will identify
    # the name of the yaml file at run time for the platform defined in run_cfg.
    platform_list = ['n1sdp', 'juno']

    run_cfg = os.environ["RUN_CONFIG"]
    res = [i for i in platform_list if i in run_cfg]
    if res:
        platform_yaml=''.join(res)+'.yaml'
    else:
        logging.critical("Exiting: Platform not found for LAVA in run-config %s", os.environ["RUN_CONFIG"])
        sys.exit(-1)

    parser = argparse.ArgumentParser(
        description="Lava job runner with infrastructure error dectection and retry."
    )
    parser.add_argument(
        "script",
        nargs="?",
        default=os.path.join(os.path.dirname(__file__), "run_lava_job.sh"),
        help="bash job script to run a lava job",
    )
    parser.add_argument(
        "job",
        nargs="?",
        default=os.path.join("artefacts", os.environ["BIN_MODE"], platform_yaml),
        help="the Lava job description file",
    )
    parser.add_argument(
        "retries",
        type=int,
        nargs="?",
        default=3,
        help="Number of retries. defaluts to 3",
    )
    parser.add_argument(
        "--save",
        default=tempfile.mkdtemp(prefix="job-output"),
        help="directory to store the job_output.log",
    )
    parser.add_argument(
        "--username",
        required=True,
        help="the user name for lava server",
    )
    parser.add_argument(
        "--token",
        required=True,
        help="the token for lava server",
    )
    parser.add_argument(
        "-v", action="count", default=0, help="Increase printing of debug ouptut"
    )
    args = parser.parse_args()
    if args.v >= 2:
        logging.getLogger().setLevel(logging.DEBUG)
    elif args.v >= 1:
        logging.getLogger().setLevel(logging.INFO)
    logging.debug(args)
    try:
        if not retry_job([args.script, args.job, args.save, args.username, args.token],\
                args.retries):
            logging.critical("All jobs failed with infra errors; retries exhausted")
            sys.exit(-1)
        else:
            sys.exit(0)
    except subprocess.CalledProcessError as e:
        logging.critical("Job script returned error code %d", e.returncode)
        sys.exit(e.returncode)
