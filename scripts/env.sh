#!/bin/bash
echo "- Setting up build environment..."

# Device Default Exports
echo "-- Exporting device settings..."
export KBUILD_BUILD_USER=hsd-compile
export KBUILD_BUILD_HOST=skernel.com
export KERNEL_NAME="-S-kernel"
export KERNEL_VERSION="4.19"
export MAIN_DEFCONFIG="arch/arm64/configs/vendor/umi_defconfig"
export ACTUAL_MAIN_DEFCONFIG="vendor/umi_defconfig"
export COMMON_DEFCONFIG="vendor/debugfs.config"
export DEVICE_DEFCONFIG="vendor/xiaomi/sm8250-common.config vendor/xiaomi/${DEVICE_IMPORT}.config"
export FEATURE_DEFCONFIG=""
export KBUILD_BUILD_USER=skernel-doped

# GCC and Clang settings
echo "-- Exporting toolchain settings..."
export CLANG_ROOT="$PWD/clang"
export GCC64_ROOT="$PWD/gcc64"
export GCC32_ROOT="$PWD/gcc32"
export PATH="$CLANG_ROOT/bin:$GCC64_ROOT/bin:$GCC32_ROOT/bin:/usr/bin:$PATH"
export MAKE_ARGS=(
        ARCH=arm64 LLVM=1 LLVM_IAS=1 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as
        NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip
        CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
        CLANG_TRIPLE=aarch64-linux-gnu-
)
TC_URLS=(
    "gcc64|https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git"
    "gcc32|https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git"
)

# Clang Setup (Neutron Clang 18.0git, tar.zst)
if [ ! -d "$CLANG_ROOT/bin" ]; then
    echo "-- Downloading Neutron Clang..."
    rm -rf "$CLANG_ROOT"
    mkdir -p "$CLANG_ROOT"
    cd "$CLANG_ROOT"
    wget -q https://github.com/Neutron-Toolchains/clang-build-catalogue/releases/download/05012024/neutron-clang-05012024.tar.zst || { echo "-- Fatal: Failed to download Neutron Clang!"; exit 1; }
    tar --use-compress-program=unzstd -xf neutron-clang-05012024.tar.zst || { echo "-- Fatal: Failed to extract Neutron Clang!"; exit 1; }
    rm neutron-clang-05012024.tar.zst
    cd - > /dev/null
else
    echo "-- Using local clang"
fi

# GCC Setup
for tc in "${TC_URLS[@]}"; do
    dir="${tc%%|*}"; url="${tc##*|}"
    if [[ "$url" == *.git ]]; then
        if [ ! -d "$dir/.git" ]; then
            echo "-- Cloning $dir..."
            rm -rf "$dir"
            git clone "$url" --depth=1 "$dir" &> /dev/null || { echo "-- Fatal: Failed to clone $dir!"; exit 1; }
        else
            echo "-- Using local $dir"
        fi
    fi
done
