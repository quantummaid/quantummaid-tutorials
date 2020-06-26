#!/usr/bin/env bash

set -euo pipefail
my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/shared.envrc"

function progress() {
  echo -e "\n==>" "$@"
}

if ${skip_sam_build_and_deploy:-false}; then
  progress "skip_sam_build_and_deploy is true, skipping..."
fi

declare -r lambda_file="cf-lambda.yml"
declare -r bucket_file="cf-bucket.yml"

#
# sam build calls mvn clean install.
# so we need to make sure it is passed the extra -DskipTests option
# so as to avoid infinite spawning of mvn processes.
#
progress "building function..."
MAVEN_OPTS="-DskipTests=true" sam build --template-file "${lambda_file}"

progress "listing jar sizes..."
du -sch .aws-sam/build/HelloWorldFunction/lib/*

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
  --s3-bucket "${bucket_name}" \
  ${sam_deploy_opts:-}
