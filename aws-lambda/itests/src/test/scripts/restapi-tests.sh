#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/shared.envrc"

function log() {
    local msg="$1" && shift
    printf "\n  - $msg\n" "$@"
}

function oneTimeSetUp() {
    readonly local api_id=$(aws cloudformation describe-stack-resource \
      --stack-name "${lambda_stack_name}" \
      --logical-resource-id HelloWorldRestApi \
      --query StackResourceDetail.PhysicalResourceId \
      --region "${region}" \
      --output text)

    declare -gr api_url=$(printf "https://%s.execute-api.%s.amazonaws.com/Prod" "${api_id}" "${region}")
}

function testFirstRequestDurationIsLessThan1500Milliseconds() {
    readonly local uuid=$(uuid)
    invokeApiAndSaveTraceId "/helloworld" 'Hello world!'
    readonly local get_trace_cmd="aws xray batch-get-traces --trace-ids ${trace_id} --query Traces[0].Duration"
    log "get_trace_cmd: ${get_trace_cmd}"
    timeout 5s bash -c "while [ \"\$($get_trace_cmd)\" == \"null\" ]; do echo \"    Waiting for trace...\"; sleep 0.1; done"
    readonly local duration_secs=$(eval "${get_trace_cmd}")
    readonly local duration_ms=$(bc <<< "$duration_secs * 1000")
    log "trace_duration: $(printf "%sms" "${duration_ms}")"
    assertTrue "the first request must take no more than 1.5s (actual: ${duration_secs}s)" "[ "${duration_ms}" -lt 1500 ]"
}

function invokeApiAndSaveTraceId() {
    readonly local path="$1"
    readonly local expect_response="$2"
    readonly local url="${api_url}${path}"
    readonly local curl_cmd="curl -Ssv \"${url}\""
    log "curl_cmd: ${curl_cmd}"
    read -a http_response <<<$(eval "${curl_cmd} 2>&1 | grep -E 'X-Amzn-Trace-Id|Hello'")
    readonly local xray_header="$(echo ${http_response[2]} | tr -d '\r')"
    readonly local actual_response="${http_response[3]} ${http_response[4]}"
    assertTrue "response has an X-Amzn-Trace-Id (url:$url, X-Amzn-Trace-Id:$xray_header)" "[[ '$xray_header' != '' ]]"
    assertEquals "response is '${expect_response}' (url:$url)" "${expect_response}" "${actual_response}"
    declare -gr trace_id=$(echo "${xray_header}" | sed "s/Root=\([^;]\+\).*/\1/1")
}

# Load shUnit2.
. "${my_dir}/shunit2"
