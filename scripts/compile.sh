#!/bin/bash

# Make sure out folder exist
mkdir -p out &> /dev/null

# Common make command array for readability
MAKE_CMD=(make O=out "${MAKE_ARGS[@]}")

# Setup main defconfig
"${MAKE_CMD[@]}" $ACTUAL_MAIN_DEFCONFIG &> /dev/null

# Append additional configs
echo "-- Appending fragments to .config..."
for fragment in $COMMON_DEFCONFIG $DEVICE_DEFCONFIG $FEATURE_DEFCONFIG; do
    if [ -f "arch/arm64/configs/$fragment" ]; then
        echo "   -> Merging $fragment..."
        cat "arch/arm64/configs/$fragment" >> out/.config
    else
        echo "   -> Warning: Fragment arch/arm64/configs/$fragment not found!"
    fi
done

# Set kernel name
echo "-- Appending kernel name..."
echo "CONFIG_LOCALVERSION=\"$KERNEL_NAME\"" >> out/.config
echo "CONFIG_LOCALVERSION_AUTO=n" >> out/.config

# Config generation
echo "-- Executing olddefconfig and syncconfig..."
{ yes "" 2>/dev/null || true; } | "${MAKE_CMD[@]}" olddefconfig &> /dev/null
{ yes "" 2>/dev/null || true; } | "${MAKE_CMD[@]}" syncconfig &> /dev/null

# Warning start banner
echo "-- Starting to compile..."
echo " "
echo "====================================="
echo " COMPILING PROCESS HAVE BEEN STARTED "
echo "====================================="
echo " "

# Compile the kernel
make -j$(nproc --all) O=out "${MAKE_ARGS[@]}"

if [ -f "out/arch/arm64/boot/Image" ]; then
    echo "The file [out/arch/arm64/boot/Image] exists. MIUI Build successfully."
else
    echo "The file [out/arch/arm64/boot/Image] does not exist. Seems MIUI build failed."
    exit 1
fi

echo "Generating [out/arch/arm64/boot/dtb]......"
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb

# Restore DTS backup for MIUI
        echo "[*] Restoring DTS backups..."
        rm -rf "${DTS_SOURCE}"
        mv "${DTS_BACKUP}" "${DTS_SOURCE}"
        echo "Finishing addind dts backup..."
# Warning finish banner
echo " "
echo "======================================"
echo " COMPILING PROCESS HAVE BEEN FINISHED "
echo "======================================"
echo " "
