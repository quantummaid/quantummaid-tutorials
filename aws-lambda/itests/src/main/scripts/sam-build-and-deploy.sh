#!/usr/bin/env bash

set -euo pipefail
my_dir="$(dirname "$(readlink -e "$0")")"

function progress() {
  echo -e "\n==>" "$@"
}

function define_shared_readonlies() {
    progress "defining shared variables..."
    declare -r   stack_identifier="${QMAIDTUTS_AWSLAMBDA_ITESTS_STACK_IDENTIFIER:-qmaidtuts-awslambda-itests}"
    declare -grx  account_id=$(aws sts get-caller-identity --query Account --output text)
    declare -grx  region=$(python -c 'import boto3; print(boto3.Session().region_name)')
    declare -grx  lambda_stack_name="${stack_identifier}-lambda"
    declare -grx  bucket_stack_name="${stack_identifier}-bucket-${account_id}-${region}"
    declare -gnrx bucket_name=bucket_stack_name
    declare -p account_id region lambda_stack_name bucket_stack_name bucket_name | tee "${my_dir}/shared.envrc"
}


define_shared_readonlies
declare -r lambda_file="cf-lambda.yml"
declare -r bucket_file="cf-bucket.yml"

if ${SAM_SKIP:-false}; then
    progress "SAM_SKIP is true, skipping..."
    exit 0
fi

progress "building..."
sam build --template-file "${lambda_file}"

progress "listing jar sizes..."
du -sch .aws-sam/build/HelloWorldFunction/{de,lib/*}

progress "deploying source bucket stack (${bucket_stack_name})..."
aws cloudformation deploy \
  --no-fail-on-empty-changeset \
  --region "${region}" \
  --stack-name "${bucket_stack_name}" \
  --template-file "${bucket_file}" \
  ${SAM_DEPLOY_ARGS:-}

progress "deploying lambda stack (${lambda_stack_name})..."
sam deploy \
  --capabilities "CAPABILITY_IAM" \
  --no-fail-on-empty-changeset \
  --region "${region}" \
  --stack-name "${lambda_stack_name}" \
  --s3-bucket "${bucket_name}"
