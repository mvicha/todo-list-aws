#! /bin/bash

user=${1}
mkdir -p resources/${user}

echo "-----BEGIN RSA PRIVATE KEY-----" > resources/${user}/key.pem
cat ${user}_key_pem | tr " " "\n" | awk '{print $1}' | tail -n +5 | egrep -v "^(-----END|RSA|PRIVATE|KEY-----)$" >> resources/${user}/key.pem
echo "-----END RSA PRIVATE KEY-----" >> resources/${user}/key.pem
chmod 700 resources/${user}/key.pem
rm ${user}_key_pem
