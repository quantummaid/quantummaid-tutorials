#!/usr/bin/env bash

set -euo pipefail
my_dir="$(dirname "$(readlink -e "$0")")"

if ${SKIP_SAM:-false}; then
    echo "SKIP_SAM is true, skipping..."
fi

function progress() {
  echo -e "\n==>" "$@"
}

function define_shared_readonlies() {
    progress "defining shared variables..."
    declare -r   stack_identifier="${QMAIDTUTS_AWSLAMBDA_ITESTS_STACK_IDENTIFIER:-qmaidtuts-awslambda-itests}"
    declare -gr  account_id=$(aws sts get-caller-identity --query Account --output text)
    declare -gr  region=$(python -c 'import boto3; print(boto3.Session().region_name)')
    declare -gr  lambda_stack_name="${stack_identifier}-lambda"
    declare -gr  bucket_stack_name="${stack_identifier}-bucket-${account_id}-${region}"
    declare -gnr bucket_name=bucket_stack_name
    declare -p account_id region lambda_stack_name bucket_stack_name bucket_name | tee "${my_dir}/.envrc"
}


define_shared_readonlies
declare -r lambda_file="cf-lambda.yml"
declare -r bucket_file="cf-bucket.yml"

progress "building..."
sam build --template-file "${lambda_file}"

progress "listing jar sizes..."
du -sch .aws-sam/build/HelloWorldFunction/{de,lib/*}

progress "deploying source bucket stack (${bucket_stack_name})..."
aws cloudformation deploy \
  --no-fail-on-empty-changeset \
  --region "${region}" \
  --stack-name "${bucket_stack_name}" \
  --template-file "${bucket_file}"

progress "deploying lambda stack (${lambda_stack_name})..."
sam deploy \
  --capabilities "CAPABILITY_IAM" \
  --no-fail-on-empty-changeset \
  --region "${region}" \
  --stack-name "${lambda_stack_name}" \
  --s3-bucket "${bucket_name}"
