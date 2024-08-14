#!/bin/bash

if [ ! -d "build_scripts" ]; then
    echo "Repo not found, cloning..."
    git clone https://github.com/Alukym/Melt-stuff.git build_scripts
else
    echo "Checking for updates..."

    cd build_scripts

    git fetch origin
    branch=$(git rev-parse --abbrev-ref HEAD)

    local_commit=$(git rev-parse "$branch")
    remote_commit=$(git rev-parse "origin/$branch")

    echo "Local : $local_commit"
    echo "Remote: $remote_commit"

    if [ "$local_commit" != "$remote_commit" ]; then
        echo "Repo is not up-to-date. Pulling latest changes..."
        git pull
    else
        echo "Repo is up-to-date!"
    fi

    git restore .

    cd ..
fi

echo ""

chmod -R 777 build_scripts
./build_scripts/build_kernel.sh "$1" "$2"