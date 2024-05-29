#!/usr/bin/env bash
set -euo pipefail

git diff $(git merge-base master upstream/master)..master \
    --diff-filter=d \
    ':(exclude).github' \
    ':(exclude)README.md' \
    ':(exclude)build.zig' \
    ':(exclude)update.sh' \
    ':(exclude)verify.sh' \
    ':(exclude).gitignore' \
    ':(exclude)build.zig.zon'
