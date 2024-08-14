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

start_count_time() {
    start_ns=$(date +'%s%N')
}

end_count_time() {
    local h min s ms ns end_ns time
    end_ns=$(date +'%s%N')
    time=$(($end_ns - $start_ns))
    [[ -z "$time" ]] && return 0
    ns=${time: -9}
    s=${time%${ns}}

    if [[ $s -ge 10800 ]]; then
        echo -e "\e[1;34m -> $1 - Time elapsed: less than 100 ms \e[0m"
    elif [[ $s -ge 3600 ]]; then
        ms=$(($ns / 1000000))
        h=$(($s / 3600))
        s=$(($s % 3600))
        if [[ $s -ge 60 ]]; then
            min=$(($s / 60))
            s=$(($s % 60))
        fi
        echo -e "\e[1;34m -> $1 <- Time elapsed: $h hr(s) $min min(s) $s sec(s) $ms ms \e[0m"
    elif [[ $s -ge 60 ]]; then
        ms=$(($ns / 1000000))
        min=$(($s / 60))
        s=$(($s % 60))
        echo -e "\e[1;34m -> $1 <- Time elapsed: $min min(s) $s sec(s) $ms ms \e[0m"
    elif [[ -n $s ]]; then
        ms=$(($ns / 1000000))
        echo -e "\e[1;34m -> $1 <- Time elapsed: $s sec(s) $ms ms \e[0m"
    else
        ms=$(($ns / 1000000))
        echo -e "\e[1;34m -> $1 <- Time elapsed: $ms ms \e[0m"
    fi
}

function build() {
    start_count_time
    make ${MAKE_ARGS} mrproper | tee ${OUT_DIR}/kernel.log
    make ${MAKE_ARGS} "$1_defconfig" | tee ${OUT_DIR}/kernel.log
    make ${MAKE_ARGS} -j$(nproc --all) | tee ${OUT_DIR}/kernel.log
    end_count_time "Build"
}

function build_clean() {
    start_count_time
    make ${MAKE_ARGS} clean
    rm -rf $OUT_DIR
    end_count_time "Clean"
}

function pack_zip() {
    local cur_date = $(date +"%Y%m%d%H%M%S")
    local zip_name = $(grep 'CONFIG_LOCALVERSION=' ./arch/arm64/configs/marble_defconfig | cut -d '"' -f 2 | sed 's/^-//')-NoKSU_$(cur_date).zip

    7z a -t7z -mx=9 ${PACK_DIR}/Image.7z ${OUT_DIR}/arch/arm64/boot/Image
    7z a -tzip -mx=9 $zip_name $PACK_DIR -xr'!build_kernel.sh'

    #cp $zip_name /mnt/g/$zip_name
}

case $1 in
"--build")
    build "$2"
    pack_zip "$2"
    ;;
"--clean")
    build_clean
    exit 0
    ;;
"-h")
    echo "Usage:"
    echo "build-kernel.sh --build your_device"
    echo "build-kernel.sh --build marble"
    echo "build-kernel.sh --clean"
    exit 1
    ;;
esac
