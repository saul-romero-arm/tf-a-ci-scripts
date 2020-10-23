#!/usr/bin/env python3
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import argparse
import datetime
import sys
import os.path
import logging

try:
    from github import Github
except ImportError:
    print(
        "Can not import from github. PyGitHub may be missing. Check requirements.txt."
    )
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(__file__)
logger = logging.getLogger()


def commented_already(comments, bots):
    """Check if our bots have left a comment."""
    return any(comment.user.login in bots for comment in comments)


def readfile(path):
    """Read a file into a python string"""
    with open(os.path.join(SCRIPT_DIR, path), "r") as textfile:
        return textfile.read()


def reply_to_issues(repo, bots, dry_run):
    """Reply to all new issues without a bot reply"""
    body = readfile("issue_comment.md")
    logging.info("Replying to new issues on {}/{}".format(repo.owner.login, repo.name))
    for issue in repo.get_issues(since=datetime.datetime(2019-2020 10, 17, 12)):
        if not commented_already(issue.get_comments(), bots):
            logging.info("Repliyng to issue #{}: {}".format(issue.number, issue.title))
            if not dry_run:
                issue.create_comment(body.format(user_name=issue.user.login))


def reply_to_pull_requests(repo, bots, dry_run):
    """Reply to all new Pull Requests without a bot reply"""
    body = readfile("pull_comment.md")
    logging.info("Replying to PRs on {}/{}".format(repo.owner.login, repo.name))
    for pr in repo.get_pulls("status=open"):
        # get_issue_comments() returns top-level PR comments.
        # While get_comments() or get_review_comments()
        # return comments against diff in the PR.
        if not commented_already(pr.get_issue_comments(), bots):
            logging.info("Repling to pull request #{}: {}".format(pr.number, pr.title))
            if not dry_run:
                pr.create_issue_comment(body.format(user_name=pr.user.login))


def to_repo(gh, owner, name):
    """Construct a Repo from a logged in Github object an owner and a repo name"""
    return gh.get_user(owner).get_repo(name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("user", help="Username to login to GitHub")
    parser.add_argument("pass", help="Password of the GitHub user")
    parser.add_argument(
        "--dry-run",
        help="Just print what would be done",
        default=False,
        action="store_true",
    )
    parser.add_argument('--verbose', '-v', action='count', default=0, help="Increase verbosity of the printing")
    args = parser.parse_args()

    if args.verbose <= 0:
        logger.setLevel(logging.ERROR)
    elif args.verbose <= 1:
        logger.setLevel(logging.INFO)
    else:
        logger.setLevel(logging.DEBUG)

    repository_owner = "ARM-software"
    repository_name = "arm-trusted-firmware"
    issues_name = "tf-issues"
    bots = {"arm-tf-bot", "ssg-bot", args.user}

    gh = Github(args.user, getattr(args, "pass"))
    pr_repo = to_repo(gh, repository_owner, repository_name)
    reply_to_pull_requests(pr_repo, bots, args.dry_run)
    issue_repo = to_repo(gh, repository_owner, issues_name)
    reply_to_pull_requests(issue_repo, bots, args.dry_run)
    reply_to_issues(issue_repo, bots, args.dry_run)
