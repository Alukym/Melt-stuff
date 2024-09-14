#!/bin/bash

REPO="git@github.com:Alukym/Melt-stuff.git"
BUILD_SCRIPT_DIR="build_scripts"

info() {
    echo -e "\e[32minfo: $1\e[0m"
}

clone_repo() {
    info "Repo not found, cloning..."
    git clone "$REPO" "$BUILD_SCRIPT_DIR"
}

update_repo() {
    info "Pulling latest changes..."
    cd "$BUILD_SCRIPT_DIR"

    git clean -fd > /dev/null
    git restore . > /dev/null

    git pull > /dev/null

    cd ..
    cp build_scripts/build.sh .
    info "Restarting script with the updated one..."
    exec ./build.sh "$1" "$2" "$3" "--skip_update"
}

# main
if [ ! -d "$BUILD_SCRIPT_DIR" ]; then
    clone_repo
elif [ $4 != "--skip_update" ]; then
    update_repo
fi

echo ""

# Ensure proper permissions
chmod -R 777 "$BUILD_SCRIPT_DIR"
"./$BUILD_SCRIPT_DIR/build_kernel.sh" "$1" "$2" "$3"
