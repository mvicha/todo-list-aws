#!/bin/sh

export PATH=${HOME}/.local/bin:${PATH}

if [ "${1}" = "local" ]; then
    export ENDPOINT_URL="http://localhost:8080/todos"
else
    export ENDPOINT_URL=$(aws cloudformation describe-stacks --stack-name todo-list-aws-${1} --query 'Stacks[0].Outputs[?OutputKey==`todoListResourceApiUrl`].OutputValue' --output text)
fi

echo 'Run final testing'
pytest tests/integration -vvv
