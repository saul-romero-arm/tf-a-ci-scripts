#!/usr/bin/env python3
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import json
import subprocess

class GerritServer:
    def __init__(self, url, port=29418):
        self.url = url
        self.port = port

    def query(self, project, q, username=None, keyfile=None):
        cmd = ["ssh", "-p", str(self.port)]

        if keyfile:
            cmd += ["-i", keyfile]
        if username:
            cmd += ["{}@{}".format(username, self.url)]
        else:
            cmd += [self.url]

        cmd += ["gerrit", "query", "--format=json", "--patch-sets",
                "--comments", "--current-patch-set",
                "project:{}".format(project)] + q

        with subprocess.Popen(cmd, stdout=subprocess.PIPE) as proc:
            changes = [json.loads(resp_line.decode()) for resp_line
                       in proc.stdout]
            if not changes:
                raise Exception("Error while querying Gerrit server {}.".format(
                    self.url))
            return changes

class GerritProject:
    def __init__(self, name, server):
        self.name = name
        self.server = server

    def query(self, q, username=None, keyfile=None):
        return self.server.query(self.name, q, username, keyfile)
