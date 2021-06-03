#!/bin/bash

service="${1}"
origin="${2}"
destination="${3}"

curpwd=${PWD}

# Clone origin Repo
git clone --mirror ${origin} /tmp/fix-${service}

# Chdir into recently cloned repo
cd "/tmp/fix-${service}"

# Remove origin
git remote rm origin

# Add destination origin
git remote add origin ${destination}

# Push everythin to the new repo
git push --all
git push --tags

cd "${curpwd}"
rm -rf "/tmp/fix-${service}"

