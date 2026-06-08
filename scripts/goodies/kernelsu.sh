#!/bin/bash

# Default exports
export SUSFS_PATCH="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch"

case "$KERNELSU_SELECTOR" in
    zako|zako-susfs)
        # Start of KernelSU integration
        echo "-- Setting up KernelSU integration: $KERNELSU_SELECTOR"
        KSU_SETUP_URI="https://github.com/ReSukiSU/ReSukiSU/raw/refs/heads/main/kernel/setup.sh"
        KSU_SETUP_BRANCH="main"

        # Check if susfs are used or not, and set the appropriate hook script URL
        if [[ "$KERNELSU_SELECTOR" == "zako-susfs" ]]; then
            KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/susfs_inline_hook_patches.sh"
        else
            KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/syscall_hook_patches.sh"
        fi

        # Setup KernelSU
        echo "-- Running KernelSU setup script..."
        curl -LSs --fail --retry 3 "$KSU_SETUP_URI" | bash -s "$KSU_SETUP_BRANCH" &> /dev/null || { echo "Fatal: KSU setup script failed to download/run!"; exit 1; }

        # Enable the necessary KernelSU configs
        echo "-- Enabling KernelSU configs..."
        echo "CONFIG_KSU=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KSU_MULTI_MANAGER_SUPPORT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KPM=n" >> $MAIN_DEFCONFIG
        echo "CONFIG_KSU_MANUAL_HOOK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THREAD_INFO_IN_TASK=y" >> $MAIN_DEFCONFIG

        # Apply KSU Hooks
        echo "-- Applying KernelSU hooks..."
        curl -LSs "$KSU_HOOK" | bash &> /dev/null

        # SUSFS Logic
        if [[ "$KERNELSU_SELECTOR" == "zako-susfs" ]]; then
            wget -qO- "$SUSFS_PATCH" | patch -s -p1 --fuzz=5 &> /dev/null
            echo "CONFIG_KSU_SUSFS=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_SUS_MAP=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> $MAIN_DEFCONFIG
        fi

        # Kernel 4.4 specific fixes
        if [[ "$KERNEL_VERSION" == "4.4" ]]; then
            echo "-- Re-tuning ksu_handle_devpts under 4.4..."
            sed -i '/static struct tty_struct \*pts_unix98_lookup/,/}/ s/ksu_handle_devpts((struct inode \*)file->f_path.dentry->d_inode);/ksu_handle_devpts(pts_inode);/' drivers/tty/pty.c
        fi
        ;;
    none|"")
        echo "-- KernelSU is not selected."
        ;;
    *)
        echo "- Invalid KERNELSU_SELECTOR: $KERNELSU_SELECTOR. Valid options: zako, zako-susfs, none."
        exit 1
        ;;
esac