#!/usr/bin/env bash

kinesis_stream_name=$1

if [ -z "$kinesis_stream_name" ]; then
    echo "Usage: $0 <kinesis-stream-name>"
    exit 1
fi

stack_names=$(aws cloudformation describe-stacks --query "Stacks[*].StackName" --output json | jq -r '.[]')
found=0

# Function to check a single stack
check_stack() {
    local stackname=$1
    if [ "$found" -eq 0 ]; then
        echo "Checking stack: $stackname"
        resource_id=$(aws cloudformation list-stack-resources --stack-name $stackname --query "StackResourceSummaries[?PhysicalResourceId=='$kinesis_stream_name'].PhysicalResourceId" --output text)

        if [ "$resource_id" == "$kinesis_stream_name" ]; then
            echo "Found in stack: $stackname"
            found=1
            kill 0  # Kill all background jobs
        fi
    fi
}

# Export the function and variable so they can be accessed by subprocesses
export -f check_stack
export kinesis_stream_name
export found

# Loop through each stack name, checking concurrently
for stackname in $stack_names; do
    check_stack $stackname &
done

# Wait for all background jobs to finish
wait

