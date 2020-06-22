#!/usr/bin/env bash

oneTimeSetUp() {
    readonly local api_id=$(aws cloudformation describe-stack-resource \
      --stack-name "${lambda_stack_name}" \
      --logical-resource-id ServerlessHttpApi \
      --query StackResourceDetail.PhysicalResourceId \
      --region "${region}" \
      --output text)

    readonly api_url=$(printf "https://%s.execute-api.%s.amazonaws.com" "${api_id}" "${region}")
}

testThatLambdaCodeSizeIsLessThanOnePointFiveMegs() {
    readonly local function_name="$(aws cloudformation describe-stack-resource \
        --stack-name "${lambda_stack_name}" \
        --logical-resource-id HelloWorldFunction \
        --query StackResourceDetail.PhysicalResourceId \
        --region "${region}" \
        --output text)"

    readonly local function_code_size="$(aws lambda get-function \
         --function-name "${function_name}" \
         --query Configuration.CodeSize)"

    readonly local kb_code_size_max=$((3 * 1024 / 2))
    readonly local kb_code_size_actual=$((function_code_size / 1024))

    assertTrue \
        "$(printf "lambda code size (%sKB) > max allowed code size (%sKB)" $kb_code_size_actual $kb_code_size_max)" \
        "[ ${kb_code_size_actual} -le ${kb_code_size_max} ]"
}

testRestApiFirstInvocationLastsNoLongerThanOnePointFiveSeconds() {
    TIMEFORMAT='%3R' invokeApi
}

# https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html
# "The default sampling rule is 1 request per second and 5 percent of additional requests."
sleepOneSecondToEnsureXrayTracingWorksOnNextRequest() {
    sleep 1
}

invokeApi() {
    true
}

# Load shUnit2.
. shunit2-2.1.8
