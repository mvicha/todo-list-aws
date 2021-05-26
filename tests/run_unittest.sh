#!/bin/sh

export PATH=${HOME}/.local/bin:${PATH}

echo 'Run unittest'
cd /opt/todo-list-aws/test/example
coverage run -m TestToDo
coverage report --include="/opt/todo-list-aws/**/*py" -m

exit 0
