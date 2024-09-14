#!/bin/bash

REPO="git@github.com:Alukym/Melt-stuff.git"
BUILD_SCRIPT_DIR="build_scripts"

# Logging functions
info() {
    echo -e "\e[32minfo\e[0m: $1"
}

warn() {
    echo -e "\e[33mwarn\e[0m: $1"
}

err() {
    echo -e "\e[31merr\e[0m : $1"
    exit 1
}

clone_repo() {
    info "Repo not found, cloning..."
    git clone "$REPO" "$BUILD_SCRIPT_DIR" > /dev/null || err "Failed to clone repo"
}

update_repo() {
    info "Pulling latest changes for build scripts..."
    cd "$BUILD_SCRIPT_DIR"

    git clean -fd > /dev/null
    git restore . > /dev/null

    git fetch origin > /dev/null || err "Failed to fetch repo"
    branch=$(git rev-parse --abbrev-ref HEAD)

    local_commit=$(git rev-parse "$branch")
    remote_commit=$(git rev-parse "origin/$branch")

    info "Local : $local_commit"
    info "Remote: $remote_commit"

    if [ "$local_commit" != "$remote_commit" ]; then
        warn "Repo is not up-to-date. Updating..."
        git pull > /dev/null || err "Failed to pull repo"

        cd ..
        cp $BUILD_SCRIPT_DIR/build.sh .
        
        warn "Restarting script with the updated version..."
        exec ./build.sh "$1" "$2" "$3"
    else
        info "Repo is up-to-date!"
        cd ..
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
