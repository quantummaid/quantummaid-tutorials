#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/common.sh"
source "${my_dir}/shared.envrc"

function oneTimeSetUp() {
    readonly local api_id=$(aws cloudformation describe-stack-resource \
      --stack-name "${lambda_stack_name}" \
      --logical-resource-id HelloWorldRestApi \
      --query StackResourceDetail.PhysicalResourceId \
      --region "${region}" \
      --output text)

    declare -gr api_url=$(printf "https://%s.execute-api.%s.amazonaws.com/Prod" "${api_id}" "${region}")
}

function testFirstFunctionInvocationDoesNotExceedMaxDuration() {
    # last trace 1-5ef626f9-c2eb0cb6b721d3c9ca622419:
    # 2020-06-26 16:48:57.11,AWS::ApiGateway::Stage,1453.00ms
    #[INFO]      [exec]     [
    #[INFO]      [exec]     "Lambda : 1450.00ms"
    #[INFO]      [exec]     ]
    _test_api_limit "/hello/first" 'Hello first!' 2500 "AWS::ApiGateway::Stage" "Lambda"
}

function testSecondFunctionInvocationDoesNotExceedMaxDuration() {
    # last trace 1-5ef626fe-70fb013085592118c53d9b98:
    # 2020-06-26 16:49:02.84,AWS::Lambda::Function,4.12ms
    #[INFO]      [exec]     [
    #[INFO]      [exec]     "Invocation : 3.68ms",
    #[INFO]      [exec]     "Overhead : 0.27ms"
    #[INFO]      [exec]     ]
    sleep 1.1 # to make sure we get an x-ray sample (it samples by default once per second)
    _test_api_limit "/hello/second" 'Hello second!' 30 "AWS::Lambda::Function" "Invocation"
}

function testThirdFunctionInvocationDoesNotExceedMaxDuration() {
    # last trace 1-5ef62704-1ad205d666256ecbedb66e83:
    # 2020-06-26 16:49:08.73,AWS::Lambda::Function,7.87ms
    #[INFO]      [exec]     [
    #[INFO]      [exec]     "Invocation : 3.22ms",
    #[INFO]      [exec]     "Overhead : 4.52ms"
    #[INFO]      [exec]     ]
    sleep 1.1 # to make sure we get an x-ray sample (it samples by default once per second)
    _test_api_limit "/hello/third" 'Hello third!' 30 "AWS::Lambda::Function" "Invocation"
}

function _test_api_limit() {
    local _path="$1"
    local _expected_response="$2"
    local _max_duration_ms="$3"
    local _origin="$4"
    local _subsegment="$5"

    _invoke_api_and_save_trace_id "${_path}" "${_expected_response}"
    _extract_trace_json_for_trace_id "${saved_trace_id}"

    local actual_duration_secs=$(_invocation_duration_in_seconds "${_origin}" "${_subsegment}" <<<"${extracted_trace_json}")
    local actual_duration_ms=$(bc <<<"scale=0; ${actual_duration_secs} * 1000 / 1")

    log "actual_duration_ms: ${actual_duration_ms}"

    assertTrue "request to '${_path}' exceeded limit (expected less than: ${_max_duration_ms} ms, actual: ${actual_duration_ms} ms)" \
        "[ "${actual_duration_ms}" -lt ${_max_duration_ms} ]"
}

function _invoke_api_and_save_trace_id() {
    local _path="$1"
    local _expect_response="$2"
    local _url="${api_url}${_path}"
    local _curl_cmd="curl -Ssi \"${_url}\""
    log "curl_cmd: ${_curl_cmd}"
    read -a http_response <<<$(eval ${_curl_cmd} 2>&1 | grep -iE '^(X-Amzn-Trace-Id|Hello )' | tr -d '\r'  | tr '\n' ' ')
    local _trace_id="$(echo ${http_response[1]})"
    local _actual_response="${http_response[2]} ${http_response[3]}"
    assertTrue "response has an X-Amzn-Trace-Id (url:$_url, X-Amzn-Trace-Id:$_trace_id)" "[[ '$_trace_id' != '' ]]"
    assertEquals "response is '${_expect_response}' (url:$_url)" "${_expect_response}" "${_actual_response}"
    declare -g saved_trace_id=$(echo "${_trace_id}" | sed "s/Root=\([^;]\+\).*/\1/1")
}

function _extract_trace_json_for_trace_id() {
    local _trace_id="$1"
    local _trace_cmd="aws xray batch-get-traces --trace-ids ${_trace_id} --output json"
    log "get_trace_cmd: ${_trace_cmd}"

    local _attempts_left=5
    until ${_trace_cmd} 2>/dev/null | _trace_json_summary &> /dev/null; do
        sleep 1s
        _attempts_left=$((_attempts_left - 1))
        if [ ${_attempts_left} -eq 0 ]; then
            return 1
        fi
    done

    timeout 5s bash -c "\
        while [ \"\$(${_trace_cmd} | jq .Traces[0].Duration)\" == \"null\" ]; do\
            echo \"     waiting for trace...\";\
            sleep 0.1;\
        done"

    log "X-Ray Summary for trace ${_trace_id}:"
    local _trace_json="$(eval "${_trace_cmd}")"
    echo "${_trace_json}" | _trace_json_summary "${_trace_id}" | log
    declare -g extracted_trace_json="${_trace_json}"
}

function _invocation_duration_in_seconds() {
    local _origin="$1"
    local _subsegment="$2"
    jq -r \
        --arg origin "${_origin}" \
        --arg subsegment "${_subsegment}" \
            '.Traces[0].Segments[].Document | fromjson |
                select(.origin == $origin) | .subsegments[] |
                    select(.name == $subsegment) |
                        (.end_time - .start_time) | @text'
}

#
# Inspiration: https://github.com/ONSdigital/es-lambda-perf-stats/blob/master/gather-stats-for-one-xray-trace.sh
# Found using: https://github.com/search?q=%22aws+xray+batch-get-traces%22+language%3Ashell&type=Code
#
function _trace_json_summary() {
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
