#!/bin/bash -e

service="${1}"
origin="${2}"
destination="${3}"

function help {
  echo "Usage: ${0} <service> <origin> <destination>"
  echo -en "\nOpciones:"
  echo -en "\n\tservice:\tNombre descriptivo del repositorio"
  echo -en "\n\torigin:\t\tRepositorio de origen"
  echo -en "\n\tdestination:\tRepositorio de destino\n\n"
}

if [[ -z "${service}" || -z "${origin}" || -z "${destination}" ]]; then
  help
  exit
fi

# Guardamos la ubicación local a donde luego volveremos
curpwd=${PWD}

# Clone origin Repo
git clone --mirror ${origin} /tmp/fix-${service} || exit 1

# Chdir into recently cloned repo
cd /tmp/fix-${service} || exit 1

# Remove origin
git remote rm origin || exit 1

# Add destination origin
git remote add origin ${destination} || exit 1

# Push everythin to the new repo
git push --all
git push --tags

cd "${curpwd}"
rm -rf "/tmp/fix-${service}"

