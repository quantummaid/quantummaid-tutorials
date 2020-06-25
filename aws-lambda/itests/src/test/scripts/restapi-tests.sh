#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/shared.envrc"

function log() {
    if [ "$#" -gt 0 ]; then
        local msg="$1" && shift
        printf "\n  - $msg\n" "$@"
    else
        printf "\n    ---\n" "$@"
        while read line; do printf "    %s\n" "${line}"; done;
        printf "\n    ---\n" "$@"
    fi
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

function testFirstLambdaRequestDoesNotExceedTheMaximumAllowed() {
    readonly local uuid=$(uuid)
    _invokeApiAndSaveTraceId "/helloworld" 'Hello world!'
    readonly local get_trace_cmd="aws xray batch-get-traces --trace-ids ${trace_id} --output json"
    log "get_trace_cmd: ${get_trace_cmd}"

    timeout 5s bash -c "\
        while [ \"\$(${get_trace_cmd} | jq .Traces[0].Duration)\" == \"null\" ]; do\
            echo \"    Waiting for trace...\";\
            sleep 0.1;\
        done"

    readonly local xray_trace_json=$(${get_trace_cmd})
    readonly local actual_duration_secs=$(jq .Traces[0].Duration <<<"${xray_trace_json}")
    readonly local actual_duration_ms=$(bc <<<"scale=0; ${actual_duration_secs} * 1000 / 1")

    log "X-Ray Summary:"
    echo "${xray_trace_json}" | _traceSummaryOfTraceId "${trace_id}" | log

    readonly local max_duration_ms="${TEST_LAMBDA_MAX_DURATION_MS:-1500}"
    assertTrue "The first request took too long
        Expected: <$(bc <<<"scale=2; ${max_duration_ms} / 1000")s
        Actual: ${actual_duration_secs}s" \
        "[ "${actual_duration_ms}" -lt ${max_duration_ms} ]"
}

function _invokeApiAndSaveTraceId() {
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

#
# Inspiration: https://github.com/ONSdigital/es-lambda-perf-stats/blob/master/gather-stats-for-one-xray-trace.sh
# Found using: https://github.com/search?q=%22aws+xray+batch-get-traces%22+language%3Ashell&type=Code
#
function _traceSummaryOfTraceId() {
    readonly local _trace_id="$1"
    jq -r '
        .Traces[0].Segments[].Document |
        fromjson | (.start_time | strftime("%Y-%m-%d %H:%M:%S")) +
                   (.start_time | @text | scan("[.][0-9]{2}")) +
        "," + .origin +
        ",\((.end_time - .start_time) * 1000 | @text |
            scan("^[^.]+.[0-9][0-9]"))ms",
        if (.subsegments | length ) !=0 then
          [.subsegments | sort_by(.start_time) | .[] |
            "\(.name) : \((.end_time - .start_time) * 1000 | @text |
              scan("^[^.]+.[0-9][0-9]"))ms"]
        else
          []
        end
    '
}

# Load shUnit2.
. "${my_dir}/shunit2"
