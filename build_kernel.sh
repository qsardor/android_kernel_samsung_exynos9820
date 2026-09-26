#!/bin/bash
# One-Click Build & Package Script for Samsung Exynos 9820 / 9825 Kernel with KernelSU-Next
# Author: Antigravity & Q.S@RDOR
set -e

DEVICE=${1:-d2xks}
SOC=exynos9825
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${ROOT_DIR}/out"
AIK_DIR="${ROOT_DIR}/prebuilts/AIK"

echo "=== Building Kernel for ${DEVICE} (${SOC}) ==="

# Toolchains
CLANG_BIN="${ROOT_DIR}/toolchain/clang/host/linux-x86/clang-4639204-cfp-jopp/bin"
GCC_BIN="${ROOT_DIR}/toolchain/gcc-cfp/gcc-cfp-jopp-only/aarch64-linux-android-4.9/bin"
export PATH="${CLANG_BIN}:${GCC_BIN}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export ARCH=arm64
export SUBARCH=arm64
export PLATFORM_VERSION=12
export ANDROID_MAJOR_VERSION=s
export CC="clang.real"
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-android-

mkdir -p "${OUT_DIR}"

echo "[1/4] Generating config (exynos9820-${DEVICE}_defconfig + ${SOC}.config)..."
make O=out ARCH=arm64 "exynos9820-${DEVICE}_defconfig"
scripts/kconfig/merge_config.sh -m -O out out/.config "arch/arm64/configs/${SOC}.config"
make O=out ARCH=arm64 olddefconfig

echo "[+] Verifying KernelSU configuration in out/.config..."
grep "^CONFIG_KSU=y" out/.config || { echo "FATAL: CONFIG_KSU is not set!"; exit 1; }
grep "^CONFIG_KSU_MANUAL_HOOK=y" out/.config || { echo "FATAL: CONFIG_KSU_MANUAL_HOOK is not set!"; exit 1; }
grep "^CONFIG_SOC_EXYNOS9825=y" out/.config || { echo "FATAL: CONFIG_SOC_EXYNOS9825 is not set!"; exit 1; }

echo "[2/4] Compiling kernel Image and DTBs..."
make -j"$(nproc)" O=out ARCH=arm64 CC="clang.real" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- Image
make -j"$(nproc)" O=out ARCH=arm64 CC="clang.real" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- dtbs

echo "[3/4] Packaging boot.img (SAR clean ramdisk, offset 0xf0000000)..."
cp "${OUT_DIR}/arch/arm64/boot/Image" "${AIK_DIR}/split_img/boot.img-kernel"
echo -n "0xf0000000" > "${AIK_DIR}/split_img/boot.img-ramdisk_offset"
: > "${AIK_DIR}/split_img/boot.img-ramdisk.cpio.gz"
cd "${AIK_DIR}"
./repackimg.sh
cd "${ROOT_DIR}"
mv "${AIK_DIR}/image-new.img" "${ROOT_DIR}/prebuilts/boot.img"

echo "[4/4] Creating dt.img, dtbo.img and Odin flashable tar..."
./prebuilts/mkdtimg cfg_create "${ROOT_DIR}/prebuilts/dt.img" "${ROOT_DIR}/prebuilts/dtconfigs/${SOC}.cfg" -d "${OUT_DIR}/arch/arm64/boot/dts/exynos"
./prebuilts/mkdtimg cfg_create "${ROOT_DIR}/prebuilts/dtbo.img" "${ROOT_DIR}/prebuilts/dtconfigs/${DEVICE}.cfg" -d "${OUT_DIR}/arch/arm64/boot/dts/samsung"

TAR_NAME="N976N_KSUN_33004_Fixed.tar"
cd "${ROOT_DIR}/prebuilts"
tar -cvf "${TAR_NAME}" boot.img dt.img dtbo.img
cd "${ROOT_DIR}"

echo "=== BUILD SUCCESSFUL ==="
echo "Flashable Odin tar: ${ROOT_DIR}/prebuilts/${TAR_NAME}"
ls -lh "${ROOT_DIR}/prebuilts/${TAR_NAME}"
