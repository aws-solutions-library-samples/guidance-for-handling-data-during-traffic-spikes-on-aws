#!/bin/bash

# CloudFormation outputs
STACK_OUTPUTS=$(aws cloudformation describe-stacks --stack-name Amcc-Stack --query 'Stacks[0].Outputs' --output json)

# Delete Route53 records
delete_route53_records() {
    echo "Deleting Route53 records..."
    HOSTED_ZONE_ID=$(echo "$STACK_OUTPUTS" | jq -r '.[] | select(.OutputKey == "HostedZoneId") | .OutputValue')
    HOSTED_ZONE_NAME=$(echo "$STACK_OUTPUTS" | jq -r '.[] | select(.OutputKey == "HostedZoneName") | .OutputValue')
    RECORD_NAME=$(echo "$STACK_OUTPUTS" | jq -r '.[] | select(.OutputKey == "RecordName") | .OutputValue')

    CURRENT_RECORDS=$(aws route53 list-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --query "ResourceRecordSets[?Name == '$RECORD_NAME.$HOSTED_ZONE_NAME.' && Type == 'CNAME']" \
        --output json)

    for record in $(echo "$CURRENT_RECORDS" | jq -c '.[]'); do
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --change-batch "{
        \"Changes\": [
        {
            \"Action\": \"DELETE\",
            \"ResourceRecordSet\": $(echo "$record" | jq '.')
        }
        ]
    }"
    done

    echo "All records have been deleted."
}

# Delete S3 bucket objects
delete_bucket_objects() {
    echo "Deleting S3 bucket objects..."
    BUCKET_NAME=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey == "AmccS3BucketName") | .OutputValue')
    aws s3 rm s3://$BUCKET_NAME --recursive
}

# Delete stacks
delete_stacks() {
    echo "Deleting Amcc-Stack stack..."
    aws cloudformation delete-stack --stack-name Amcc-Stack
    aws cloudformation wait stack-delete-complete --stack-name Amcc-Stack
}

# Execute the script
delete_route53_records
delete_bucket_objects
delete_stacks

echo "Cleanup completed!"