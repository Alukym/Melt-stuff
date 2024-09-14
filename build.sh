#!/bin/bash

REPO="git@github.com:Alukym/Melt-stuff.git"
DIR="build_scripts"
BUILD_SCRIPT="build_kernel.sh"

info() {
    echo -e "\e[32minfo: $1\e[0m"
}

clone_repo() {
    info "Repo not found, cloning..."
    git clone "$REPO" "$DIR"
}

update_repo() {
    info "Pulling latest changes..."
    cd "$DIR" || exit 1

    # git clean -fd
    # git restore .

    git pull

    cd .. || exit 1
}

# main
if [ ! -d "$DIR" ]; then
    clone_repo
else
    update_repo
fi

echo ""

# Ensure proper permissions
chmod -R 777 "$DIR"
"./$DIR/$BUILD_SCRIPT" "$1" "$2" "$3"
