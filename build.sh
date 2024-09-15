#!/bin/bash

set -o pipefail

REPO="git@github.com:Alukym/Melt-stuff.git"
BUILD_SCRIPT_DIR="build_scripts"

# Store script arguments
SCRIPT_ARGS=("$@")

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
    info "Build scripts are not found, cloning..."
    git clone "$REPO" "$BUILD_SCRIPT_DIR" > /dev/null || err "Failed to clone repo"
}

update_repo() {
    info "Pulling latest changes for build scripts..."
    cd "$BUILD_SCRIPT_DIR"

    git clean -fd > /dev/null
    git restore . > /dev/null

    # this command outputs in stderr so we use 2>&1
    git fetch origin > /dev/null 2>&1 || err "Failed to fetch repo"
    branch=$(git rev-parse --abbrev-ref HEAD)

    local_commit=$(git rev-parse "$branch")
    remote_commit=$(git rev-parse "origin/$branch")

    info "Local : $local_commit"
    info "Remote: $remote_commit"

    if [ "$local_commit" != "$remote_commit" ]; then
        warn "Build scripts are not up-to-date. Updating..."
        git pull > /dev/null || err "Failed to pull repo"

        cd ..
        cp $BUILD_SCRIPT_DIR/build.sh .

        warn "Restarting script with the updated version..."
        exec ./build.sh "${SCRIPT_ARGS[@]}"
    else
        info "Build scripts are up-to-date!"
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

exec "./$BUILD_SCRIPT_DIR/build_kernel.sh" "${SCRIPT_ARGS[@]}"
