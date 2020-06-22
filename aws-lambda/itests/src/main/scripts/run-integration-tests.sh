#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/common.sh"
test_dir="$(dirname "$(dirname "${my_dir}")")/test/scripts"

declare -x account_id region lambda_stack_name bucket_stack_name bucket_name

cd "${test_dir}"
for test_script in *-tests.sh; do
    banner "running ${test_script}..."
    bash "${test_script}"
done
