#!/bin/sh

export PATH=${HOME}/.local/bin:${PATH}

if [ ${1} ]; then
    export ENDPOINT_URL=$(aws cloudformation describe-stacks --stack-name todo-list-aws-staging --query 'Stacks[0].Outputs[?OutputKey==`todoListResourceApiUrl`].OutputValue' --output text)
else
    export ENDPOINT_URL="http://dynamodb:8080"
fi

echo 'Run final testing'
cd /opt/todo-list-aws/test/unit
pytest test_create.py -vvv
