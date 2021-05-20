#!/bin/sh

export PATH=${HOME}/.local/bin:${PATH}

export ENDPOINT_URL=$(aws cloudformation describe-stacks --stack-name todo-list-aws-staging --query 'Stacks[0].Outputs[?OutputKey==`todoListResourceApiUrl`].OutputValue' --output text)

echo 'Run final testing'
cd /opt/todo-list-aws/test/unit
pytest test_create.py -vvv
