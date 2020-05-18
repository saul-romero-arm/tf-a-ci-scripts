#!/usr/bin/env python3
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import argparse
import datetime
import os
import sys

# suds is not a standard library package. Although it's installed in the Jenkins
# slaves, it might not be so in the user's machine (when running Coverity scan
# on there).
try:
    import suds
except ImportError:
    print(" You need to have suds Python3 package to query Coverity server")
    print(" pip3 install suds-py3")
    sys.exit(0)

# Get coverity host from environment, or fall back to the default one.
coverity_host = os.environ.get("coverity_host", "coverity.cambridge.arm.com")
coverity_port = os.environ.get("coverity_port", "8443")

parser = argparse.ArgumentParser()

parser.add_argument("--description", help="Snapshot description filter")
parser.add_argument("--file", dest="output_file", help="Output file. Mandatory")
parser.add_argument("--old", default=10, help="Max snapshot age in days")
parser.add_argument("--host", default=coverity_host, help="Coverity server")
parser.add_argument("--https-port", default=coverity_port, help="Coverity Secure port")
parser.add_argument("--version", help="Snapshot version filter")
parser.add_argument("stream_name")

opts = parser.parse_args()

if not opts.output_file:
    raise Exception("Must specify an output file")

# We output the snapshot ID to the specified file. In case of any errors, we
# remove the file, and Coverity wrapper can test for its existence.
try:
    user = os.environ["TFCIBOT_USER"]
    password = os.environ["TFCIBOT_PASSWORD"]
except:
    print(" Unable to get credentials for user tfcibot")
    print(" For potentially faster analysis, suggest set "
        "TFCIBOT_PASSWORD and TFCIBOT_PASSWORD in the environment")
    sys.exit(0)

# SOAP magic stuff
client = suds.client.Client("https://{}/ws/v9/configurationservice?wsdl".format(opts.host))
security = suds.wsse.Security()
token = suds.wsse.UsernameToken(user, password)
security.tokens.append(token)
client.set_options(wsse=security)

# Construct stream ID data object
streamid_obj = client.factory.create("streamIdDataObj")
streamid_obj.name = opts.stream_name

# Snapshot filter
filter_obj = client.factory.create("snapshotFilterSpecDataObj")

# Filter snapshots for age
past = datetime.date.today() - datetime.timedelta(days=opts.old)
filter_obj.startDate = past.strftime("%Y-%m-%d")

if opts.version:
    filter_obj.versionPattern = opts.version

if opts.description:
    filter_obj.descriptionPattern = opts.description

# Query server
results = client.service.getSnapshotsForStream(streamid_obj, filter_obj)

# Print ID of the last snapshot if results were returned
if results:
    try:
        with open(opts.output_file, "w") as fd:
            print(results[-1].id, file=fd)
    except:
        os.remove(opts.output_file)
        raise
