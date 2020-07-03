#!/usr/bin/env bash

set -euo pipefail
my_dir="$(dirname "$(readlink -e "$0")")"

function progress() {
  echo -e "\n==>" "$@"
}

function define_shared_readonlies() {
    progress "defining shared variables..."
    declare -r   stack_identifier="${STACK_IDENTIFIER:-qmaidtuts-awslambda-itests}"
    declare -grx  account_id=$(aws sts get-caller-identity --query Account --output text)
    declare -grx  region=$(python -c 'import boto3; print(boto3.Session().region_name)')
    declare -grx  lambda_stack_name="${stack_identifier}-lambda"
    declare -grx  bucket_stack_name="${stack_identifier}-bucket-${account_id}-${region}"
    declare -gnrx bucket_name=bucket_stack_name
    case "${TEST_MODE:-SKIP}" in
        NORMAL)
            progress "NORMAL testMode"
            declare -grx  skip_sam_build_and_deploy=false
            declare -grx  skip_run_integration_tests=false
            declare -grx  skip_teardown=true
        ;;
        RELEASE)
            progress "RELEASE testMode"
            declare -grx  skip_sam_build_and_deploy=false
            declare -grx  skip_run_integration_tests=false
            declare -grx  skip_teardown=false
        ;;
        SKIP)
            progress "SKIP testMode"
            declare -grx  skip_sam_build_and_deploy=true
            declare -grx  skip_run_integration_tests=true
            declare -grx  skip_teardown=true
        ;;
        *)
            progress "unhandled testMode '${testMode}', aborting..."
            exit 1
        ;;
    esac
    declare -p account_id region \
        lambda_stack_name bucket_stack_name bucket_name \
        skip_sam_build_and_deploy skip_run_integration_tests skip_teardown |
            tee "${my_dir}/shared.envrc"
}

define_shared_readonlies
