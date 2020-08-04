#!/usr/bin/env python3
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# Assigns reviewers according to maintainers file.

import argparse
import os
from pygerrit2 import GerritRestAPI, HTTPBasicAuth
import re

DEFAULT_GERRIT_URL = 'https://review.trustedfirmware.org'
DEFAULT_GERRIT_PROJECT_NAME = 'TF-A/trusted-firmware-a'
DEFAULT_MAINTAINERS_FILE_NAME = 'maintainers.rst'

# Commit message is returned in a file list, ignore it
COMMIT_MSG_FILE = '/COMMIT_MSG'

def connect_to_gerrit(gerrit_url, gerrit_user, gerrit_password):
    '''
    Connect to Gerrit server.
    The password is not a plaintext password,
    it can be obtained from Profile/Settings/HTTP Password page.
    Returns GerritRestAPI class.
    '''

    auth = HTTPBasicAuth(gerrit_user, gerrit_password)
    return GerritRestAPI(url=gerrit_url, auth=auth)


def get_open_changes(rest_api, project_name):
    '''
    Get list of open reviews for the project.
    '''

    # Pass DETAILED_ACCOUNTS to get owner username
    return rest_api.get("/changes/?q=status:open%20project:" + project_name + "&o=DETAILED_ACCOUNTS")


def get_files(rest_api, change_id):
    '''
    Get list of changed files for the review.
    Commit message is removed from the list.
    '''

    files_list = rest_api.get("/changes/" + change_id + "/revisions/current/files/")
    del files_list[COMMIT_MSG_FILE]

    return files_list


def add_reviewer(rest_api, change_id, username, dry_run):
    '''
    Add reviewer to the review.
    '''

    endpoint = "/changes/" + change_id + "/reviewers"
    kwargs = {"data": {"reviewer": username}}

    # Exception is thrown if username is wrong, so just print it
    try:
        if not dry_run:
            rest_api.post(endpoint, **kwargs)
    except Exception as e:
        print("  Add reviewer failed, username: " + str(username))
        print("  " + str(e))
    else:
        print("  Reviewer added, username: " + str(username))


def parse_maintainers_file(file_path):
    '''
    Parse maintainers file.
    Returns a dictionary {file_path:set{user1, user2, ...}}
    '''

    f = open(file_path, encoding='utf8')
    file_text = f.read()
    f.close()

    FILE_PREFIX = "\n:F: "

    regex = r"^:G: `(?P<user>.*)`_$(?P<paths>(" + FILE_PREFIX + r".*$)+)"
    matches = re.finditer(regex, file_text, re.MULTILINE)

    # Create a dictionary {file_path:set{user1, user2, ...}} for faster search
    result_dict = {}

    for match in matches:
        user_name = match.group("user")

        paths = match.group("paths").split(FILE_PREFIX)
        paths.remove("")

        # Fill the dictionary
        for path in paths:
            if path not in result_dict:
                result_dict[path] = set()

            result_dict[path].add(user_name)

    return result_dict


def get_file_maintainers(file_path, maintainers_dictionary):
    '''
    Returns a set of usernames(mainteiners) for the file.
    '''

    maintainers = set()

    file = file_path

    # Get maintainers of the file
    maintainers_set = maintainers_dictionary.get(file)
    if maintainers_set:
        maintainers.update(maintainers_set)

    # Get maintainers of the directories
    while (file > "/"):
        # Get upper directory on each step.
        file = os.path.dirname(file)
        path_to_check = file + "/"

        maintainers_set = maintainers_dictionary.get(path_to_check)
        if maintainers_set:
            maintainers.update(maintainers_set)

    return maintainers


def assign_reviewers(rest_api, maintainers_dictionary, change, dry_run):
    '''
    Assign maintainers to the review.
    '''

    # It looks like some accounts may not have username
    owner_username = None
    if ('username' in change['owner']):
        owner_username = change['owner']['username']

    print("\nChange: " + str(change['id']))
    print("  Topic: " + str(change.get('topic')))
    print("  Owner: " + str(owner_username))

    change_maintainers = set()

    # Get list of all files in the change
    files = get_files(rest_api, change['id'])

    for file in files:
        # Get all maintainers of the file
        file_maintainers = get_file_maintainers(file, maintainers_dictionary)

        if (len(file_maintainers) > 0):
            print("  File: " + file + " maintainers: " + str(file_maintainers))

        change_maintainers.update(file_maintainers)

    # Don't add owner even if he is a maintainer
    change_maintainers.discard(owner_username)

    for maintainer in change_maintainers:
        add_reviewer(rest_api, change['id'], maintainer, dry_run)


def parse_cmd_line():

    parser = argparse.ArgumentParser(
        description="Gerrit bot",
        epilog="""
            Assigns reviewers according to maintainers file.
        """
    )

    required_group = parser.add_argument_group('required arguments')

    parser.add_argument("--url", "-u",
                        help = """
                        Gerrit URL (default: %(default)s)
                        """,
                        default = DEFAULT_GERRIT_URL)

    parser.add_argument("--project", "-p",
                        help = """
                        Project name (default: %(default)s).
                        """,
                        default = DEFAULT_GERRIT_PROJECT_NAME)

    parser.add_argument("--maintainers", "-m",
                        help = """
                        Path to maintainers file (default: %(default)s).
                        """,
                        default = DEFAULT_MAINTAINERS_FILE_NAME)

    parser.add_argument("--dry-run",
                        help = """
                        Check maintainers, but don't add them (default: %(default)s).
                        """,
                        action='store_true',
                        default = False)

    required_group.add_argument("--user",
                        help = """
                        Gerrit user.
                        """,
                        required = True)

    required_group.add_argument("--password",
                        help="""
                        Gerrit HTTP password.
                        This is NOT a plaintext password.
                        But the value from Profile/Settings/HTTP Password
                        """,
                        required = True)

    return parser.parse_args()


if __name__ == '__main__':

    args = parse_cmd_line()

    maintainers_dict = parse_maintainers_file(args.maintainers)
    rest = connect_to_gerrit(args.url, args.user, args.password)
    changes = get_open_changes(rest, args.project)

    for change in changes:
        assign_reviewers(rest, maintainers_dict, change, args.dry_run)
