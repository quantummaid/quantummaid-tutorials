#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -e "$0")")"
source "${my_dir}/common.sh"
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
    # 2020-06-26: actual_code_size_kb: 1293
    readonly local max_code_size_kb=1400
    #Showcase end maxCodeSize
    readonly local actual_code_size_kb=$((function_code_size / 1024))

    log "actual_code_size_kb: ${actual_code_size_kb}"

    assertTrue \
        "$(printf "lambda code size (%sKB) > max allowed code size (%sKB)" $actual_code_size_kb $max_code_size_kb)" \
        "[ ${actual_code_size_kb} -le ${max_code_size_kb} ]"
}

# Load shUnit2.
echo "> jar-tests.sh:pwd: $(pwd)"
echo "> jar-tests.sh:\$0: ${0}"
echo "> jar-tests.sh:\$my_dir: ${my_dir}"
ls -la "${my_dir}"

. "${my_dir}/shunit2"
