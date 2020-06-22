#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/common.sh"

exit 0

readonly lambda_file="cf-lambda.yml"
readonly bucket_file="cf-bucket.yml"

banner "building..."
sam build --template-file "${lambda_file}"

banner "listing sizes..."
du -sch .aws-sam/build/HelloWorldFunction/{de,lib/*}

banner "source bucket name: ${bucket_name}"
banner "deploying source bucket stack..."
aws cloudformation deploy \
  --no-fail-on-empty-changeset \
  --region "${region}" \
  --stack-name "${bucket_stack_name}" \
  --template-file "${bucket_file}"

banner "lambda stack name: ${lambda_stack_name}"
banner "deploying lambda stack..."
sam deploy \
  --capabilities "CAPABILITY_IAM" \
  --no-fail-on-empty-changeset \
  --region "${region}" \
  --stack-name "${lambda_stack_name}" \
  --s3-bucket "${bucket_name}"
