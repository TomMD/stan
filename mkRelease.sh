#!/usr/bin/env bash
name=$(date +"%Y%b%d")
if [[ -x ${name} ]] ; then
    echo "Directory named '${name}' already exists.  Remove it."
    exit 1
fi
mkdir ${name}
docker build -t stan-release-image .
id=$(docker create stan-release-image)
docker cp "$id:/stan" "./${name}/stan"
docker rm "$id"
cp CHANGELOG.md README.md LICENSE ${name}
name=$(date +"%Y%b%d")
tar cJf stan-${name}.tar.xz "${name}"
