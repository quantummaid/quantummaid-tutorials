#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/common.sh"

banner "removing lambda stack..."
aws cloudformation delete-stack --region "${region}" --stack-name "${lambda_stack_name}"

banner "removing bucket stack..."
aws cloudformation delete-stack --region "${region}" --stack-name "${bucket_stack_name}"
