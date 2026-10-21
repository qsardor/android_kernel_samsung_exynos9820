#!/bin/bash
# One-Click Build & Package Script for Samsung Exynos 9820 / 9825 Kernel with KernelSU-Next & SuSFS
# Author: Antigravity & Q.S@RDOR
set -e

DEVICE=${1:-d2xks}
SOC=exynos9825
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${ROOT_DIR}/out"
AIK_DIR="${ROOT_DIR}/prebuilts/AIK"

if [ "${DEVICE}" = "d1xks" ]; then
    MODEL_NAME="N971N"
    BOARD_ID="SRPSD23A002KU"
elif [ "${DEVICE}" = "d2xks" ]; then
    MODEL_NAME="N976N"
    BOARD_ID="SRPSD23C002KU"
else
    MODEL_NAME="${DEVICE}"
    BOARD_ID="SRPSD23C002KU"
fi

echo "=========================================================="
echo "=== Building Kernel for ${MODEL_NAME} (${DEVICE} / ${SOC}) ==="
echo "    Board ID: ${BOARD_ID}"
echo "    Attribution: Created by Antigravity & Q.S@RDOR"
echo "=========================================================="

# Auto-acquire toolchain if missing (for GitHub Actions CI or fresh clones)
if [ ! -d "${ROOT_DIR}/toolchain/clang" ] || [ ! -d "${ROOT_DIR}/toolchain/gcc-cfp" ]; then
    echo "[*] Toolchains not found, downloading CFP Clang & GCC toolchain..."
    mkdir -p "${ROOT_DIR}/toolchain"
    TOOLCHAIN_URL="https://github.com/GoRhanHee/exynos9820_toolchain/releases/download/toolchain/toolchain.tar.xz"
    curl -fsSL "$TOOLCHAIN_URL" -o /tmp/toolchain.tar.xz
    tar -xf /tmp/toolchain.tar.xz -C "${ROOT_DIR}"
    rm -f /tmp/toolchain.tar.xz
    echo "[+] Toolchains acquired successfully."
fi

# Toolchains PATH
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
export KSU_VERSION_OVERRIDE=33355
export KSU_VERSION_TAG_OVERRIDE="v3.4.2"

mkdir -p "${OUT_DIR}"

echo "[1/4] Generating config (exynos9820-${DEVICE}_defconfig + ${SOC}.config)..."
cd "${ROOT_DIR}"
make O=out ARCH=arm64 "exynos9820-${DEVICE}_defconfig"
scripts/kconfig/merge_config.sh -m -O out out/.config "arch/arm64/configs/${SOC}.config"

# Inject device-specific model config
sed -i '/CONFIG_MODEL_/d' out/.config
MODEL_UPPER="$(echo ${DEVICE} | tr '[:lower:]' '[:upper:]')"
echo "CONFIG_MODEL_${MODEL_UPPER}=y" >> out/.config
make O=out ARCH=arm64 olddefconfig

echo "[+] Verifying KernelSU & Model configuration in out/.config..."
grep "^CONFIG_KSU=y" out/.config || { echo "FATAL: CONFIG_KSU is not set!"; exit 1; }
grep "^CONFIG_KSU_MANUAL_HOOK=y" out/.config || { echo "FATAL: CONFIG_KSU_MANUAL_HOOK is not set!"; exit 1; }
grep "^CONFIG_KSU_SUSFS=y" out/.config || { echo "FATAL: CONFIG_KSU_SUSFS is not set!"; exit 1; }
grep "^CONFIG_SOC_EXYNOS9825=y" out/.config || { echo "FATAL: CONFIG_SOC_EXYNOS9825 is not set!"; exit 1; }
grep "^CONFIG_MODEL_${MODEL_UPPER}=y" out/.config || { echo "FATAL: CONFIG_MODEL_${MODEL_UPPER} is not set!"; exit 1; }

echo "[2/4] Compiling kernel Image and DTBs..."
make -j"$(nproc)" O=out ARCH=arm64 CC="clang.real" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- Image
make -j"$(nproc)" O=out ARCH=arm64 CC="clang.real" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- dtbs

echo "[3/4] Packaging boot.img for ${MODEL_NAME} (Board: ${BOARD_ID})..."
cp "${OUT_DIR}/arch/arm64/boot/Image" "${AIK_DIR}/split_img/boot.img-kernel"
echo -n "${BOARD_ID}" > "${AIK_DIR}/split_img/boot.img-board"
echo -n "0x01000000" > "${AIK_DIR}/split_img/boot.img-ramdisk_offset"
echo -n "androidboot.super_partition=system androidboot.mode=normal" > "${AIK_DIR}/split_img/boot.img-cmdline"
cd "${AIK_DIR}"
./repackimg.sh
cd "${ROOT_DIR}"
mkdir -p "${ROOT_DIR}/prebuilts"
mv "${AIK_DIR}/image-new.img" "${ROOT_DIR}/prebuilts/boot.img"
rm -f "${AIK_DIR}/split_img/boot.img-kernel"

echo "[4/4] Creating dt.img, dtbo.img and flashable packages..."
./prebuilts/mkdtimg cfg_create "${ROOT_DIR}/prebuilts/dt.img" "${ROOT_DIR}/prebuilts/dtconfigs/${SOC}.cfg" -d "${OUT_DIR}/arch/arm64/boot/dts/exynos"
./prebuilts/mkdtimg cfg_create "${ROOT_DIR}/prebuilts/dtbo.img" "${ROOT_DIR}/prebuilts/dtconfigs/${DEVICE}.cfg" -d "${OUT_DIR}/arch/arm64/boot/dts/samsung"

TAR_NAME="${MODEL_NAME}_KSUN_33355_v3.4.2_SUSFS_v1.5.5.tar"
ZIP_NAME="${MODEL_NAME}_KSUN_33355_v3.4.2_SUSFS_v1.5.5.zip"

cd "${ROOT_DIR}/prebuilts"
tar -cvf "${TAR_NAME}" boot.img dt.img dtbo.img
zip -r9 "${ZIP_NAME}" boot.img dt.img dtbo.img META-INF
cd "${ROOT_DIR}"

echo "=== BUILD SUCCESSFUL ==="
echo "Odin Tar: ${ROOT_DIR}/prebuilts/${TAR_NAME}"
echo "TWRP Zip: ${ROOT_DIR}/prebuilts/${ZIP_NAME}"
ls -lh "${ROOT_DIR}/prebuilts/${TAR_NAME}" "${ROOT_DIR}/prebuilts/${ZIP_NAME}"

SCRATCH_DIR="/mnt/c/Users/Sardor/.gemini/antigravity/scratch"
if [ -d "$SCRATCH_DIR" ]; then
    cp -f "${ROOT_DIR}/prebuilts/${TAR_NAME}" "${ROOT_DIR}/prebuilts/${ZIP_NAME}" "$SCRATCH_DIR/"
    echo "Copied packages to scratch directory."
fi
