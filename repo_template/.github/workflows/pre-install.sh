#!/bin/bash
# Runs after Python/tooling install and before package install.
# This hook may run more than once in a workflow, so keep it idempotent.
# Edit this file only if the workflow needs extra system packages or Python tooling.

# Example: install Linux system dependencies
# if [[ "$RUNNER_OS" == "Linux" ]]; then
#   sudo apt-get update
#   sudo apt-get install -y \
#     libmariadb3 libmariadb-dev \
#     unixodbc unixodbc-dev
# fi

# Example: install extra Python tooling
# pip install keyring keyrings.alt
