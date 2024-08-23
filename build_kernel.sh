#!/bin/bash

# make sure current dir is '.', not './build_scripts'
PACK_DIR=$(dirname "$0")
cd "${PACK_DIR}/.."

OUT_DIR=out
MAKE_ARGS=\
"ARCH=arm64 \
LLVM=1 \
LLVM_IAS=1 \
O=$OUT_DIR"

#                  $1       $2
# function build(ksu_arg, device)
function build() {
    if [ -e "./arch/arm64/configs/$2_defconfig" ]; then
        echo "Error: $2_defconfig does not exist!"
        exit 1
    fi

    # remove old ksu config
    sed -i '/^CONFIG_KSU=/d' "./arch/arm64/configs/$2_defconfig"
    if [ "$1" == "--ksu" ]; then
        echo "CONFIG_KSU=y" >> "./arch/arm64/configs/$2_defconfig"
    fi


    make ${MAKE_ARGS} mrproper | tee ${OUT_DIR}/kernel.log
    make ${MAKE_ARGS} "$2_defconfig" | tee ${OUT_DIR}/kernel.log
    make ${MAKE_ARGS} -j$(nproc --all) | tee ${OUT_DIR}/kernel.log

    # remove again
    sed -i '/^CONFIG_KSU=/d' "./arch/arm64/configs/$2_defconfig"
}

function build_clean() {
    make ${MAKE_ARGS} clean
    rm -rf $OUT_DIR
}

#                     $1       $2
# function pack_zip(ksu_arg, device)
function pack_zip() {
    # remove old files
    rm Melt-*.zip 2>/dev/null
    #rm /mnt/g/Melt-*.zip 2>/dev/null

    # update sha1 in anykernel.sh
    new_sha1=$(sha1sum "${OUT_DIR}/arch/arm64/boot/Image" | awk '{ print $1 }')
    sed -i "s/^SHA1_STOCK=.*/SHA1_STOCK=\"${new_sha1}\"/" ${PACK_DIR}/anykernel.sh

    if [ "$1" == "--ksu" ]; then
        ksu_type="KSU"
    else
        ksu_type="NoKSU"
    fi

    local cur_date="$(date +"%Y%m%d%H%M%S")"
    local zip_name="$(grep 'CONFIG_LOCALVERSION=' arch/arm64/configs/$2_defconfig | cut -d '"' -f 2 | sed 's/^-//')-${ksu_type}_${cur_date}.zip"

    # compressing

    # save cur dir
    pushd $(pwd) >/dev/null

    # enter target dir
    cd ${OUT_DIR}/arch/arm64/boot/
    echo "Compressing kernel Image"
    7z a -t7z -mx=9 ../../../../${PACK_DIR}/Image.7z Image -bso0
    echo "Done!"

    popd >/dev/null

    echo "Compressing zip for flashing"
    7z a -tzip -mx=9 $zip_name $PACK_DIR/* -xr'!build.sh' -xr'!build_kernel.sh' -xr'!.git' -bso0
    echo "Done!"
    
    echo "====================================================="
    echo -e "Output archive: \e[1;34m${zip_name}\e[0m"
    echo "====================================================="

    # for my own purposes
    # cp $zip_name /mnt/g/$zip_name
}

function show_usage() {
    echo "Usage:"
    echo "build.sh   b   |      <--ksu>       |    your_device"
    echo "         build | enable ksu support | marble for default"
    echo "build.sh   c"
    echo "         clean"
}

case $1 in
"b")
    if [ -z "$3" ]; then
        set -- "$1" "$2" "marble"
    fi
    if [ "$2" != "--ksu" ]; then
        set -- "$1" "" "$3"
    fi

    build "$2" "$3"
    pack_zip "$2" "$3"

    exit 0
    ;;
"c")
    build_clean

    exit 0
    ;;
esac

show_usage
exit 1
