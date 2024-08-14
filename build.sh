#!/bin/bash

REPO="https://github.com/Alukym/Melt-stuff.git"

if [ ! -d "build_scripts" ]; then
    echo "Repo not found, cloning..."
    git clone $REPO build_scripts
else
    echo "Checking for updates..."

    cd build_scripts

    # clean changes
    git clean -fd
    git restore .

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

    cd ..
fi

echo ""

chmod -R 777 build_scripts
./build_scripts/build_kernel.sh "$1" "$2"