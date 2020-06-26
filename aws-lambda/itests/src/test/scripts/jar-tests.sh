#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/shared.envrc"

testThatLambdaCodeSizeDoesNotExceedMaxCodeSize() {
    readonly local function_name="$(aws cloudformation describe-stack-resource \
        --stack-name "${lambda_stack_name}" \
        --logical-resource-id HelloWorldFunction \
        --query StackResourceDetail.PhysicalResourceId \
        --region "${region}" \
        --output text)"

    readonly local function_code_size="$(aws lambda get-function \
         --function-name "${function_name}" \
         --query Configuration.CodeSize)"

    #Showcase start maxCodeSize
    readonly local max_code_size_kb=$(bc <<<"1024 * 1.5 / 1")
    #Showcase end maxCodeSize
    readonly local actual_code_size_kb=$((function_code_size / 1024))

    assertTrue \
        "$(printf "lambda code size (%sKB) > max allowed code size (%sKB)" $actual_code_size_kb $max_code_size_kb)" \
        "[ ${actual_code_size_kb} -le ${max_code_size_kb} ]"
}

# Load shUnit2.
. "${my_dir}/shunit2"
