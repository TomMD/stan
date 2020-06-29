#!/usr/bin/env bash

set -e

function mkStan() {
    local ghc_version=$1
    local name="stan-x64-Linux-$(date +"%Y%b%d")-ghc-${ghc_version}"
    if [[ -x ${name} ]] ; then
        echo "Directory named '${name}' already exists.  Remove it."
        exit 1
    fi
    mkdir ${name}
    docker build --build-arg ghc_version_arg=$ghc_version -t stan-release-image .
    id=$(docker create stan-release-image)
    docker cp "$id:/stan" "./${name}/stan"
    docker rm "$id"
    cp CHANGELOG.md README.md LICENSE "${name}"
    tar cJf "${name}.tar.xz" "${name}"
}

mkStan "8.8.3"
mkStan "8.10.1"
