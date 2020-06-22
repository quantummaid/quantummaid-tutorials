#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/common.sh"

banner "removing lambda stack..."
aws cloudformation delete-stack \
  --region "${region}" \
  --stack-name "${stack_name}"
