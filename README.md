# android_kernel_samsung_exynos9820

Production-grade Samsung Exynos 9820/9825 kernel with integrated KernelSU-Next v3.4.1 (Driver: 33333, UAPI: 5).

![Architecture](https://img.shields.io/badge/Architecture-aarch64-blue)
![Kernel](https://img.shields.io/badge/Linux-4.14.113-green)
![KernelSU-Next](https://img.shields.io/badge/KernelSU--Next-v3.4.1--legacy-orange)
![License](https://img.shields.io/badge/License-GPL--2.0-red)

<p align="center">
  <img src="./docs/ksu_working.png" alt="KernelSU-Next Working on Note 10+ 5G" width="360" />
</p>

## Why

Stock and community kernel trees for Samsung Exynos 9820/9825 fail when compiling with modern root solutions due to four fundamental blockers:
1. **Non-GKI Syscall Intercept Trap:** Missing `0xDEADBEEF` early-return in `kernel/reboot.c` and missing `ksu_handle_setresuid` in `kernel/sys.c` cause manager supercall failures (`errno 22 EINVAL`) and prevent Zygote `[ksu_driver]` file-descriptor injection.
2. **SAR Ramdisk Freezes:** Upstream boot ramdisk injection corrupts Samsung One UI 4.1 System-as-Root (SAR), causing early bootloader freezes and bootloops.
3. **VFS ABBA Deadlock:** Synchronous `fsnotify` parsing in `pkg_observer.c` blocks on `i_rwsem` during Android PMS startup, hanging `system_server` in uninterruptible sleep (`D` state).
4. **SoC Configuration Conflict:** Default configs conflate Exynos 9820 (S10) with Exynos 9825 (Note 10), leading to clock and power-management stalls on `d2xks`.

This repository provides surgical, production-tested fixes for all four issues, enabling stable, out-of-the-box KernelSU-Next v3.4.1 execution on One UI 4.1.

## Quick Start

```bash
git clone --depth=1 https://github.com/qsardor/android_kernel_samsung_exynos9820.git -b gorhanhee
cd android_kernel_samsung_exynos9820
./build_kernel.sh d2xks
```

The compiled, Odin-flashable archive will be generated at `prebuilts/N976N_KSUN_33333_v3.4.1.tar`.

## Features

- **Built-in KernelSU-Next Legacy v3.4.1 (33333):** Integrated in-tree under `drivers/kernelsu` with manual hook mode and UAPI 5 support.
- **Surgical Non-GKI Supercalls:** Early return on `0xDEADBEEF` in `kernel/reboot.c` and clean Zygote credential specialization in `kernel/sys.c`.
- **Asynchronous Package Observer:** Replaces synchronous `fsnotify` parsing with non-blocking Linux workqueues (`schedule_work`), eliminating `system_server` uninterruptible sleep.
- **Clean SAR Boot:** Preserves stock Samsung SAR rootfs structure with zero ramdisk corruption.
- **Automated Crowning Service:** Includes `tools/ksu_manager_guard/00-crown-manager.sh` to dynamically crown manager UIDs across cold reboots.
- **Single-Command Odin Packaging:** Automatically packages `boot.img`, `dt.img`, and `dtbo.img` into a flashable `.tar`.
- **Automated Toolchain Acquisition:** `build_kernel.sh` automatically downloads and unpacks the required Samsung CFP Clang 6.0.1 and GCC 4.9 CFP toolchains on demand.

## Supported Devices

| Codename | Device | SoC | Defconfig |
| :--- | :--- | :--- | :--- |
| `d2xks` | Galaxy Note 10+ 5G (`SM-N976N`) | Exynos 9825 | `exynos9820-d2xks_defconfig` |
| `d2s` | Galaxy Note 10 (`SM-N970F`) | Exynos 9825 | `exynos9820-d2s_defconfig` |
| `d2x` | Galaxy Note 10+ (`SM-N975F`) | Exynos 9825 | `exynos9820-d2x_defconfig` |
| `beyond1lte` | Galaxy S10 (`SM-G973F`) | Exynos 9820 | `exynos9820-beyond1lte_defconfig` |
| `beyond2lte` | Galaxy S10+ (`SM-G975F`) | Exynos 9820 | `exynos9820-beyond2lte_defconfig` |
| `beyond0lte` | Galaxy S10e (`SM-G970F`) | Exynos 9820 | `exynos9820-beyond0lte_defconfig` |

## Build Environment

- **Architecture:** `arm64` (aarch64)
- **Compiler:** Clang 6.0.1 (`clang-4639204-cfp-jopp`)
- **Cross-Compiler:** GCC 4.9 CFP (`aarch64-linux-android-`)
- **Target OS:** Android 12 (One UI 4.1)

## Credits

Created together by **Antigravity** & **Q.S@RDOR**.

## License

This project is licensed under the [GNU General Public License v2.0](LICENSE).
