#!/bin/sh

export PATH=${HOME}/.local/bin:${PATH}

echo 'Run static code check'
result=$(radon cc /opt/todo-list-aws/ -a -nc)

if [ -n "${result}" ]; then
  echo ${result}
  exit 1
else
  echo "Static Code Check executed successfully"
fi

echo 'Run pep8 validations'
flake8 /opt/todo-list-aws/
if [ ${?} -ne 0 ]; then
  echo ${result}
  exit 1
else
  echo "PEP8 validation checks executed successfully"
fi

exit 0
