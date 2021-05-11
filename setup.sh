#!/bin/bash

cat <<EOF > ~/.vimrc
:set number
:set tabstop=2       " The width of a TAB is set to 2.
                    " Still it is a \t. It is just that
                    " Vim will interpret it to be having
                    " a width of 2.

:set shiftwidth=2    " Indents will have a width of 2

:set softtabstop=2   " Sets the number of columns for a TAB

:set expandtab       " Expand TABs to spaces
EOF

git clone https://github.com/mvicha/todo-list-serverless.git my-todo-list-serverless.git

sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel
sudo curl -fsSL -o /opt/Python-3.8.2.tgz https://www.python.org/ftp/python/3.8.2/Python-3.8.2.tgz
sudo tar -C /opt -xzf /opt/Python-3.8.2.tgz
cd /opt/Python-3.8.2
sudo ./configure --enable-optimizations
sudo make altinstall
python3.8 --version


npm install -g serverless
docker container run -d --name dynamo --rm -p 8000:8000 amazon/dynamodb-local

echo "REMEMBER TO SET SERVERLESS_ACCESS_KEY"
echo "Add Serverless Provider Role in ORG"
echo "Create Serverless App with proper values based on the serverless.yml file"
echo "sls create --template-url https://github.com/mvicha/todo-list-serverless.git --name todo-list-serverless"
echo "npm install && sls deploy --org YOUR_SERVERLESS_ORG"
