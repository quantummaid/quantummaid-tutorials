#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/.envrc"

oneTimeSetUp() {
    readonly local api_id=$(aws cloudformation describe-stack-resource \
      --stack-name "${lambda_stack_name}" \
      --logical-resource-id ServerlessHttpApi \
      --query StackResourceDetail.PhysicalResourceId \
      --region "${region}" \
      --output text)

    readonly api_url=$(printf "https://%s.execute-api.%s.amazonaws.com" "${api_id}" "${region}")
}

testHttpApiFirstInvocationLastsNoLongerThanOnePointFiveSeconds() {
    TIMEFORMAT='%3R' invokeApi "/helloworld" 'Hello world!'
}

# https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html
# "The default sampling rule is 1 request per second and 5 percent of additional requests."
sleepOneSecondToEnsureXrayTracingWorksOnNextRequest() {
    sleep 1
}

invokeApi() {
    readonly local path="$1"
    readonly local expect_response="$2"
    readonly local actual_response=$(curl -Ss "${api_url}${path}")
    assertEquals "GET ${api_url}${path} responds with '${expect_response}'" "${expect_response}" "${actual_response}"
}

# Load shUnit2.
. "${my_dir}/shunit2"
