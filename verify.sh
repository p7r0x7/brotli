#!/bin/sh

set -eu
git diff "$(git merge-base master upstream/master)"..master \
    --diff-filter=d \
    ':(exclude)README.md' \
    ':(exclude)build.zig' \
    ':(exclude)update.sh' \
    ':(exclude)verify.sh' \
    ':(exclude).gitignore' \
    ':(exclude)LICENSE.txt' \
    ':(exclude)build.zig.zon'
