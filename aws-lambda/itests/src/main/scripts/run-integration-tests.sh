#!/usr/bin/env bash

set -euo pipefail
my_dir="$(dirname "$(readlink -e "$0")")"
test_dir="$(dirname "$(dirname "${my_dir}")")/test/scripts"

function progress() {
  echo -e "\n==>" "$@"
}

cd "${test_dir}"
for test_script in *-tests.sh; do
    progress "running ${test_script}..."
    bash "${test_script}"
done
