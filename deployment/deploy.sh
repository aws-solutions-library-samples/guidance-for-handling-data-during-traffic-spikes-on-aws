#!/bin/bash
region=$(aws configure get region)
template_url=""

# Define Function
create_bucket() {
    aws_account_id=$(aws sts get-caller-identity --query Account --output text)
    bucket_name="amcc-template-bucket-${aws_account_id}"
    aws s3 mb s3://${bucket_name}
    echo "S3 bucket ${bucket_name} created."
}

upload_files() {
    local file="$1"
    if [ -f "$file" ]; then
        aws s3 cp "$file" "s3://${bucket_name}/$(basename "$file")"
        template_url="https://${bucket_name}.s3.${region}.amazonaws.com/Amcc-Stack.yaml"
    else
        echo "File not found: $file"
        return 1
    fi
}

create_stackset() {
    stack_name="Amcc-Stack"

    aws cloudformation create-stack --stack-name $stack_name \
        --template-url $template_url \
        --capabilities CAPABILITY_NAMED_IAM

    # echo "StackSet ${stack_set_name} created."
}

# Main
main() {
    create_bucket
    upload_files "./source/templates/Amcc-Stack.yaml"
    create_stackset
}

# Run
main