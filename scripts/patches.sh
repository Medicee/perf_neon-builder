#!/bin/bash
echo "- Applying device specific patches for umi..."

# Patcher helper - 1.5
apply_patches() {
    for patch_url in "$@"; do
        echo "-- Applying patch: $(basename "$patch_url")"
        curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_patch.patch
        if [ -s /tmp/temp_patch.patch ]; then
            patch -s -p1 --fuzz=5 < /tmp/temp_patch.patch || { echo "Fatal: Failed to apply patch!"; exit 1; }
        else
            echo "Fatal: Failed to download patch from $patch_url"
            exit 1
        fi
    done
}

# Commit reverter - 1.5
revert_commit() {
    for patch_url in "$@"; do
        echo "-- Reverting commit: $(basename "$patch_url")"
        curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_revert.patch
        if [ -s /tmp/temp_revert.patch ]; then
            patch -R -s -p1 < /tmp/temp_revert.patch || { echo "Fatal: Failed to revert commit!"; exit 1; }
        else
            echo "Fatal: Failed to download revert patch from $patch_url"
            exit 1
        fi
    done
}

# Shared patches for 4.14
LTO_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/fix_lto.patch"
KPATCH_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/kpatch_fix.patch"

# Patcher - 1.0
# Set drivers as built in for 4.19
echo "-- Setting up drivers as built-in..."
sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/perf/Kconfig
sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/shs/Kconfig
# Common configs for 4.19
echo "-- Tuning default configs..."
echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
