#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/.envrc"

function progress() {
    local msg="$1" && shift
    printf "\n==> $msg" "$@"
}

function oneTimeSetUp() {
    readonly local api_id=$(aws cloudformation describe-stack-resource \
      --stack-name "${lambda_stack_name}" \
      --logical-resource-id ServerlessHttpApi \
      --query StackResourceDetail.PhysicalResourceId \
      --region "${region}" \
      --output text)

    readonly api_url=$(printf "https://%s.execute-api.%s.amazonaws.com" "${api_id}" "${region}")
}

function testFirstInvocationLastsNoLongerThanOnePointFiveSeconds() {
    readonly local before=$(currentTimeMillis)
    invokeApi "/helloworld" 'Hello world!'
    readonly local after=$(currentTimeMillis)
    declare -i elapsed_time_millis=$after-$before
    progress "first invocation took %sms" $elapsed_time_millis
    assertTrue "invoking the api for the first time takes less than 1.5s" "[ $elapsed_time_millis -lt 1500 ]"
    sleepOneSecondToEnsureXrayTracingWorksOnNextRequest
}

function currentTimeMillis() {
    date +%s%N | cut -b1-13
}

function invokeApi() {
    readonly local path="$1"
    readonly local expect_response="$2"
    readonly local curl_cmd="curl -Ss \"${api_url}${path}\""
    progress "${curl_cmd}"
    readonly local actual_response=$(eval "${curl_cmd}")
    assertEquals "GET ${api_url}${path} responds with '${expect_response}'" "${expect_response}" "${actual_response}"
}

# https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html
# "The default sampling rule is 1 request per second and 5 percent of additional requests."
function sleepOneSecondToEnsureXrayTracingWorksOnNextRequest() {
    sleep 1
}

# Load shUnit2.
. "${my_dir}/shunit2"
