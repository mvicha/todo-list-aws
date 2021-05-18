#!/bin/sh

export PATH=${HOME}/.local/bin:${PATH}

echo 'Run unittest'
cd /opt/todo-list-serverless/test/example
coverage run -m TestToDo
coverage report --include="/opt/todo-list-serverless/**/*py" -m

exit 0
