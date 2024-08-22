#!/bin/bash

# make sure current dir is '.', not './Melt-stuff'
PACK_DIR=$(dirname "$0")
cd "${PACK_DIR}/.."

OUT_DIR=out
MAKE_ARGS=\
"ARCH=arm64 \
LLVM=1 \
LLVM_IAS=1 \
O=$OUT_DIR"

# start_count_time() {
#     start_ns=$(date +'%s%N')
# }
#
# end_count_time() {
#     local h=0 min=0 s=0 ms=0 ns=0 end_ns time
#     end_ns=$(date +'%s%N')
#     time=$(($end_ns - $start_ns))
#
#     # check if $time is zero or negative, which should not be the case but added for safety reasons
#     [[ -z "$time" || "$time" -le 0 ]] && return 0
#     
#     # strip leading zeros
#     ns=$((${time: -9} + 0))
#     s=${time%${ns}}
#
#     if [[ $s -ge 10800 ]]; then
#         echo -e "\e[1;34m-> $1 - Time elapsed: more than 3 hours \e[0m"
#     elif [[ $s -ge 3600 ]]; then
#         ms=$(($ns / 1000000))
#         h=$(($s / 3600))
#         s=$(($s % 3600))
#         min=$(($s / 60))
#         s=$(($s % 60))
#         echo -e "\e[1;34m-> $1 <- Time elapsed: $h hr(s) $min min(s) $s sec(s) $ms ms \e[0m"
#     elif [[ $s -ge 60 ]]; then
#         ms=$(($ns / 1000000))
#         min=$(($s / 60))
#         s=$(($s % 60))
#         echo -e "\e[1;34m-> $1 <- Time elapsed: $min min(s) $s sec(s) $ms ms \e[0m"
#     elif [[ -n $s ]]; then
#         ms=$(($ns / 1000000))
#         echo -e "\e[1;34m-> $1 <- Time elapsed: $s sec(s) $ms ms \e[0m"
#     else
#         ms=$(($ns / 1000000))
#         echo -e "\e[1;34m-> $1 <- Time elapsed: $ms ms \e[0m"
#     fi
# }


function build() {
    #start_count_time
    make ${MAKE_ARGS} mrproper | tee ${OUT_DIR}/kernel.log
    make ${MAKE_ARGS} "$1_defconfig" | tee ${OUT_DIR}/kernel.log
    make ${MAKE_ARGS} -j$(nproc --all) | tee ${OUT_DIR}/kernel.log
    #end_count_time "Build"
}

function build_clean() {
    #start_count_time
    make ${MAKE_ARGS} clean
    rm -rf $OUT_DIR
    #end_count_time "Clean"
}

function pack_zip() {
    #start_count_time

    # remove old files
    rm Melt-*.zip 2>/dev/null
    rm /mnt/g/Melt-*.zip 2>/dev/null

    # update sha1 in anykernel.sh
    new_sha1=$(sha1sum "${OUT_DIR}/arch/arm64/boot/Image" | awk '{ print $1 }')
    sed -i "s/^SHA1_STOCK=.*/SHA1_STOCK=\"${new_sha1}\"/" ${PACK_DIR}/anykernel.sh

    local cur_date="$(date +"%Y%m%d%H%M%S")"
    local zip_name="$(grep 'CONFIG_LOCALVERSION=' arch/arm64/configs/$1_defconfig | cut -d '"' -f 2 | sed 's/^-//')-NoKSU_${cur_date}.zip"

    # compressing

    # save cur dir
    pushd $(pwd) >/dev/null

    # enter target dir
    cd ${OUT_DIR}/arch/arm64/boot/
    echo "Compressing kernel Image"
    7z a -t7z -mx=9 ../../../../${PACK_DIR}/Image.7z Image -bso0
    echo "Done!"

    # return to original dir
    popd >/dev/null

    echo "Compressing zip for flashing"
    7z a -tzip -mx=9 $zip_name $PACK_DIR/* -xr'!build.sh' -xr'!build_kernel.sh' -xr'!.git' -bso0
    echo "Done!"

    #end_count_time "Pack"
    
    echo "====================================================="
    echo -e "Output archive: \e[1;34m${zip_name}\e[0m"
    echo "====================================================="

    cp $zip_name /mnt/g/$zip_name
}

function show_usage() {
    echo "Usage:"
    echo "build_kernel.sh --build your_device"
    echo "build_kernel.sh --build marble"
    echo "build_kernel.sh --pack"
    echo "build_kernel.sh --clean"
}

case $1 in
"--build")
    build "$2"
    pack_zip "$2"

    exit 0
    ;;
"--pack")
    pack_zip "marble"

    exit 0
    ;;
"--clean")
    build_clean

    exit 0
    ;;
esac

show_usage
exit 1
