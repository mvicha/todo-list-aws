#!/bin/sh

export PATH=${HOME}/.local/bin:${PATH}

echo 'Run final testing'
cd /opt/todo-list-aws/test/unit
pytest test_create.py -vvv
