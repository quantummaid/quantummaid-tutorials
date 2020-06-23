#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/shared.envrc"

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

# Load shUnit2.
. "${my_dir}/shunit2"
