#!/bin/sh

echo 'Run unittest'
cd /opt/todo-list-serverless/test/example
coverage run -m TestToDo
coverage report -m

exit 0
