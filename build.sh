#!/bin/bash

REPO="git@github.com:Alukym/Melt-stuff.git"
BUILD_SCRIPT_DIR="build_scripts"

warn() {
    echo -e "\e[33mwarn: $1\e[0m"
}

info() {
    echo -e "\e[32minfo: $1\e[0m"
}

err() {
    echo -e "\e[31merr : $1\e[0m"
    exit 1
}

clone_repo() {
    info "Repo not found, cloning..."
    git clone "$REPO" "$BUILD_SCRIPT_DIR" | err "Failed to clone repo"
}

update_repo() {
    info "Pulling latest changes..."
    cd "$BUILD_SCRIPT_DIR"

    git clean -fd > /dev/null
    git restore . > /dev/null

    git fetch origin > /dev/null | err "Failed to fetch repo"
    branch=$(git rev-parse --abbrev-ref HEAD)

    local_commit=$(git rev-parse "$branch")
    remote_commit=$(git rev-parse "origin/$branch")

    info "Local : $local_commit"
    info "Remote: $remote_commit"

    if [ "$local_commit" != "$remote_commit" ]; then
        warn "Repo is not up-to-date. Pulling latest changes..."
        git pull > /dev/null | err "Failed to pull repo"

        cd ..
        cp build_scripts/build.sh .
        
        warn "Restarting script with the updated version..."
        exec ./build.sh "$1" "$2" "$3"
    else
        info "Repo is up-to-date!"
    fi
}

# main
if [ ! -d "$BUILD_SCRIPT_DIR" ]; then
    clone_repo
else
    update_repo
fi

echo ""

# Ensure proper permissions
chmod -R 777 "$BUILD_SCRIPT_DIR"

exec "./$BUILD_SCRIPT_DIR/build_kernel.sh" "$1" "$2" "$3"
