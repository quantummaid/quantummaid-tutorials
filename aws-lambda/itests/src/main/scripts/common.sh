set -euo pipefail

function banner() {
  echo -e "\n==>" "$@"
}

banner "determining account id..."
readonly account_id=$(aws sts get-caller-identity --query Account --output text)
banner "account id: ${account_id}"

banner "determining region..."
readonly region=$(python -c 'import boto3; print(boto3.Session().region_name)')
banner "region: ${region}"

readonly stack_identifier="${QMAIDTUTS_AWSLAMBDA_ITESTS_STACK_IDENTIFIER:-qmaidtuts-awslambda-itests}"
readonly lambda_stack_name="${stack_identifier}-lambda"
readonly bucket_stack_name="${stack_identifier}-bucket-${account_id}-${region}"
declare -n bucket_name=bucket_stack_name
