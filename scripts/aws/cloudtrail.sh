#!/bin/bash

# Variables
MAX_RESULTS=50
NEXT_TOKEN=""
EVENT_NAME=$1
STREAM_NAME=$2  # Stream name to match, passed as the second argument

if [ -z "$EVENT_NAME" ] || [ -z "$STREAM_NAME" ]; then
    echo "Usage: $0 <EventName> <StreamName>"
    exit 1
fi

echo "Searching for events with EventName: $EVENT_NAME and StreamName: $STREAM_NAME"

while true; do
    # Build the base command with EventName filter
    if [ -z "$NEXT_TOKEN" ]; then
        COMMAND="aws cloudtrail lookup-events --max-results $MAX_RESULTS --lookup-attributes AttributeKey=EventName,AttributeValue=$EVENT_NAME"
    else
        COMMAND="aws cloudtrail lookup-events --max-results $MAX_RESULTS --lookup-attributes AttributeKey=EventName,AttributeValue=$EVENT_NAME --next-token $NEXT_TOKEN"
    fi

    # Execute the command and store the result
    RESPONSE=$($COMMAND)

    # Check for errors
    if [ $? -ne 0 ]; then
        echo "Error fetching events. Exiting."
        exit 1
    fi

    # Filter events for the specified stream name
    MATCH=$(echo "$RESPONSE" | grep -i "$STREAM_NAME")

    if [ ! -z "$MATCH" ]; then
        echo "Matching events found:"
        echo "$MATCH"
    else
        echo "No matching events found in this batch."
    fi

    # Extract the NextToken for pagination
    NEXT_TOKEN=$(echo "$RESPONSE" | grep -o '"NextToken":"[^"]*' | grep -o '[^"]*$')

    if [ -z "$NEXT_TOKEN" ]; then
        echo "No more events to process."
        break
    fi

    # Extract the timestamp of the last event
    LAST_EVENT_TIME=$(echo "$RESPONSE" | grep -o '"EventTime":"[^"]*' | tail -1 | grep -o '[^"]*$')
    echo "Fetching next set of events... Last event timestamp: $LAST_EVENT_TIME"
done

echo "Search completed."
