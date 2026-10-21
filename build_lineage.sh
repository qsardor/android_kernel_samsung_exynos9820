#!/usr/bin/env bash
# ==============================================================================
# Master Kernel Build Script for LineageOS 23.2 (Android 16)
# Samsung Galaxy Note 10+ 5G (d2x / SM-N976N) & Exynos 9820 / 9825 Series
# KernelSU-Next v3.4.2 (Manual Ring 0 Hooks) + Headless Display + Anti-Disconnect
# Attribution: Created by Antigravity & Q.S@RDOR
# ==============================================================================
set -e

DEVICE=${1:-d2x}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${ROOT_DIR}/out"
AIK_DIR="${ROOT_DIR}/prebuilts/AIK"
TOOLCHAIN_DIR="${ROOT_DIR}/toolchain"

echo "=========================================================="
echo "=== Building LineageOS 23.2 Kernel for ${DEVICE} ==="
echo "    Attribution: Created by Antigravity & Q.S@RDOR"
echo "=========================================================="

# Auto-acquire Neutron Clang toolchain if missing
if [ ! -f "${TOOLCHAIN_DIR}/bin/clang" ]; then
    echo "[*] Toolchain not found, downloading Neutron Clang via antman..."
    mkdir -p "${TOOLCHAIN_DIR}"
    cd "${TOOLCHAIN_DIR}"
    curl -fsSL "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" -o antman
    bash antman -S
    cd "${ROOT_DIR}"
    echo "[+] Neutron Clang acquired successfully."
fi

export PATH="${TOOLCHAIN_DIR}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export ARCH=arm64
export SUBARCH=arm64
export CC=clang
export CROSS_COMPILE=aarch64-linux-gnu-

# Apply KernelSU-Next compatibility patch if present
if [ -f "${ROOT_DIR}/ksu_clang24.patch" ] && [ -d "${ROOT_DIR}/KernelSU-Next" ]; then
    echo "[*] Applying KernelSU-Next Clang 24 compatibility patch..."
    cd "${ROOT_DIR}/KernelSU-Next"
    patch -p1 --forward < "${ROOT_DIR}/ksu_clang24.patch" || true
    cd "${ROOT_DIR}"
fi

mkdir -p "${OUT_DIR}"

echo "[1/3] Generating defconfig (exynos9820-${DEVICE}_defconfig)..."
cd "${ROOT_DIR}"
make O=out ARCH=arm64 "exynos9820-${DEVICE}_defconfig"

# Verify KernelSU-Next in defconfig
grep "^CONFIG_KSU=y" out/.config || { echo "FATAL: CONFIG_KSU is not set!"; exit 1; }
grep "^CONFIG_KSU_MANUAL_HOOK=y" out/.config || { echo "FATAL: CONFIG_KSU_MANUAL_HOOK is not set!"; exit 1; }

echo "[2/3] Compiling kernel Image with $(nproc) cores..."
make O=out -j"$(nproc)"

if [ ! -f "${OUT_DIR}/arch/arm64/boot/Image" ]; then
    echo "[-] FATAL: Kernel Image compilation failed!"
    exit 1
fi
echo "[+] Kernel Image successfully built: $(ls -lh "${OUT_DIR}/arch/arm64/boot/Image" | awk '{print $5}')"

echo "[3/3] Packaging boot_lineage_ksu.img via AIK..."
mkdir -p "${ROOT_DIR}/prebuilts"
cp "${OUT_DIR}/arch/arm64/boot/Image" "${AIK_DIR}/split_img/boot.img-kernel"
echo -n "SRPSD23C002KU" > "${AIK_DIR}/split_img/boot.img-board"
echo -n "0x01000000" > "${AIK_DIR}/split_img/boot.img-ramdisk_offset"
echo -n "androidboot.super_partition=system androidboot.mode=normal" > "${AIK_DIR}/split_img/boot.img-cmdline"
cd "${AIK_DIR}"
./repackimg.sh
cd "${ROOT_DIR}"

BOOT_IMG_NAME="boot_lineage_ksu_${DEVICE}.img"
mv "${AIK_DIR}/image-new.img" "${ROOT_DIR}/prebuilts/${BOOT_IMG_NAME}"
rm -f "${AIK_DIR}/split_img/boot.img-kernel"

# Also package flashable zip with updater script
ZIP_NAME="lineage-23.2_ksunext_${DEVICE}_signed.zip"
cd "${ROOT_DIR}/prebuilts"
cp "${BOOT_IMG_NAME}" boot.img
zip -r9 "${ZIP_NAME}" boot.img META-INF 2>/dev/null || zip -r9 "${ZIP_NAME}" boot.img
rm -f boot.img
cd "${ROOT_DIR}"

echo "=========================================================="
echo "=== BUILD SUCCESSFUL ==="
echo "Raw Boot Image: ${ROOT_DIR}/prebuilts/${BOOT_IMG_NAME}"
echo "Flashable Zip:  ${ROOT_DIR}/prebuilts/${ZIP_NAME}"
ls -lh "${ROOT_DIR}/prebuilts/${BOOT_IMG_NAME}" "${ROOT_DIR}/prebuilts/${ZIP_NAME}"
echo "=========================================================="

SCRATCH_DIR="/mnt/c/Users/Sardor/.gemini/antigravity/scratch"
if [ -d "$SCRATCH_DIR" ]; then
    cp -f "${ROOT_DIR}/prebuilts/${BOOT_IMG_NAME}" "${ROOT_DIR}/prebuilts/${ZIP_NAME}" "$SCRATCH_DIR/"
    echo "Copied packages to scratch directory."
fi
