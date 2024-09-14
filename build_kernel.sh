#!/bin/bash

# Set initial directories to "./" , not "./build_scripts"
PACK_DIR=$(dirname "$0")
cd "${PACK_DIR}/.." || err "Failed to change directory to ${PACK_DIR}/.."

OUT_DIR=out
MAKE_ARGS="ARCH=arm64 LLVM=1 LLVM_IAS=1 O=$OUT_DIR"

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

build_kernel() {
    local ksu_arg=$1
    local device=$2
    local defconfig="./arch/arm64/configs/${device}_defconfig"

    if [ ! -e "$defconfig" ]; then
        err "${device}_defconfig does not exist!"
        exit 1
    fi

    info "Building kernel..."

    sed -i '/^CONFIG_KSU=/d' "$defconfig"
    
    if [ "$ksu_arg" == "--ksu" ]; then
        echo "CONFIG_KSU=y" >> "$defconfig" || err "Failed to add KSU config"
    fi

    # Clean and compile the kernel
    make $MAKE_ARGS mrproper > /dev/null | tee ${OUT_DIR}/kernel.log || err "Failed to run make mrproper. Check ${OUT_DIR}/kernel.log"
    make $MAKE_ARGS "${device}_defconfig" > /dev/null | tee -a ${OUT_DIR}/kernel.log || err "Failed to configure device $device. Check ${OUT_DIR}/kernel.log"
    make $MAKE_ARGS -j$(nproc --all) > /dev/null | tee -a ${OUT_DIR}/kernel.log || err "Kernel build failed. Check ${OUT_DIR}/kernel.log"

    sed -i '/^CONFIG_KSU=/d' "$defconfig" || err "Failed to clean up KSU config in ${device}_defconfig"
}

build_clean() {
    make $MAKE_ARGS clean > /dev/null || err "Failed to run make clean"
    rm -rf $OUT_DIR || err "Failed to remove output directory $OUT_DIR"
}

pack_zip() {
    local ksu_arg=$1
    local device=$2

    rm Melt*.zip 2>/dev/null

    local new_sha1
    new_sha1=$(sha1sum "${OUT_DIR}/arch/arm64/boot/Image" | awk '{ print $1 }') || err "Failed to calculate SHA1 for Kernel Image: ${OUT_DIR}/arch/arm64/boot/Image"
    sed -i "s/^SHA1_STOCK=.*/SHA1_STOCK=\"${new_sha1}\"/" "${PACK_DIR}/anykernel.sh"

    local ksu_type="NoKSU"
    [ "$ksu_arg" == "--ksu" ] && ksu_type="KSU"

    local cur_date
    cur_date=$(date +"%Y%m%d%H%M%S") || err "Failed to get current date"
    local zip_name="$(grep 'CONFIG_LOCALVERSION=' arch/arm64/configs/${device}_defconfig | cut -d '"' -f 2 | sed 's/^-//')-${ksu_type}_${cur_date}.zip"

    pushd "${OUT_DIR}/arch/arm64/boot/" > /dev/null
    info "Compressing kernel Image..."
    7z a -t7z -mx=9 "../../../../../${PACK_DIR}/Image.7z" Image -bso0 || err "Failed to compress kernel image"
    info "Done!"
    popd > /dev/null || err "Failed to return to previous directory"

    info "Compressing zip for flashing..."
    7z a -tzip -mx=9 "$zip_name" $PACK_DIR/* -xr'!build.sh' -xr'!build_kernel.sh' -xr'!.git' -bso0 || err "Failed to compress flashable zip"
    info "Done!"

    echo "====================================================="
    echo -e "Output archive: \e[1;34m${zip_name}\e[0m"
    echo "====================================================="
}

show_usage() {
    echo "Usage:"
    echo "build.sh   b   |      <--ksu>       |    your_device"
    echo "         build | enable ksu support | marble for default"
    echo "build.sh   c"
    echo "         clean"
}

# main
case $1 in
    "b")
        device=${3:-"marble"}
        ksu_arg=${2:-""}
        [ "$ksu_arg" != "--ksu" ] && ksu_arg=""

        build_kernel "$ksu_arg" "$device"
        pack_zip "$ksu_arg" "$device"
        ;;
    "c")
        build_clean
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
