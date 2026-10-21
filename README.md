# android_kernel_samsung_exynos9820

Production-grade Linux 4.14 kernels for Samsung Exynos 9820/9825 devices, engineered for headless edge computing, LineageOS 23.2 (Android 16), Stock One UI 5.1 (Android 12), and KernelSU-Next with automated GitHub Actions CI/CD.

[![LineageOS 23.2 CI](https://github.com/qsardor/android_kernel_samsung_exynos9820/actions/workflows/build_lineage.yml/badge.svg?branch=lineage-23.2)](https://github.com/qsardor/android_kernel_samsung_exynos9820/actions/workflows/build_lineage.yml)
[![Stock One UI CI](https://github.com/qsardor/android_kernel_samsung_exynos9820/actions/workflows/build.yml/badge.svg?branch=susfs-next-gen)](https://github.com/qsardor/android_kernel_samsung_exynos9820/actions/workflows/build.yml)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)

---

> [!IMPORTANT]
> ### 🖥️ Headless Appliance Note & LineageOS Optimization
> This kernel and build system are customized for a **headless Samsung Galaxy Note 10+ 5G (`SM-N976N` / `d2x`, Exynos 9825, 12 GB RAM)** operating as an autonomous, 24/7 home server with a broken or detached AMOLED display and touch digitizer.
>
> Stock firmware and generic AOSP kernels frequently fail on headless boards due to display driver panics, wake-lock stalls, and USB lockscreen drops. To make LineageOS 23.2 deployment and remote management seamless, this tree incorporates:
> 1. **MIPI LCD Hardware Bypass (`drivers/video/fbdev/exynos/dpu20/panels/common_mipi_lcd.c`):** Neutralizes display driver panic loops when the device boots without an active AMOLED panel connected.
> 2. **USB ConfigFS Anti-Disconnect (`drivers/usb/gadget/configfs.c`):** Blocks Android userspace lockscreen and charging policies from dropping USB data lines or unregistering UDC gadgets, guaranteeing unbroken Root ADB access over USB and Wi-Fi.
> 3. **Normal Boot Enforcer (`boot.img-cmdline`):** Pre-injected with `androidboot.super_partition=system androidboot.mode=normal` to ensure deterministic normal boot directly from partition `boot` (`sda14`), eliminating recovery boot traps.
> 4. **Automated AIK Repackaging:** Includes integrated Android Image Kitchen (AIK) logic to output both raw `boot.img` and flashable recovery `.zip` packages on every build.

---

## 🌳 Branch Architecture

| Branch | Target Operating System | Linux Kernel | Toolchain | Root & Stealth Stack | CI/CD Workflow |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`lineage-23.2`** | LineageOS 23.2 (Android 16) | `4.14.356-openela-rc1` | Neutron Clang 24 (`antman`) | KernelSU-Next v3.4.2 (Ring 0 Hooks) | [build_lineage.yml](.github/workflows/build_lineage.yml) |
| **`susfs-next-gen`** | Stock One UI 5.1 (Android 12) | `4.14.113` | Samsung CFP Clang 6.0 + GCC 4.9 | KernelSU-Next v3.4.2 + SuSFS v1.5.5 | [build.yml](.github/workflows/build.yml) |

---

## ⚡ Quick Start: Zero-Storage Cloud Build

Kernel compilation is offloaded to GitHub Actions runners to preserve local disk space and compute resources.

### Trigger Remote Cloud Build (GitHub CLI)

```bash
# Build LineageOS 23.2 (Android 16) Kernel for Galaxy Note 10+ 5G (d2x)
gh workflow run "build_lineage.yml" --repo qsardor/android_kernel_samsung_exynos9820 --ref lineage-23.2 -f device=d2x

# Build Stock One UI 5.1 Kernel with SuSFS for Galaxy Note 10+ 5G (d2xks)
gh workflow run "build.yml" --repo qsardor/android_kernel_samsung_exynos9820 --ref susfs-next-gen -f device=d2xks

# Download flashable artifacts from the completed run
gh run download <RUN_ID> --repo qsardor/android_kernel_samsung_exynos9820
```

### Local Compilation (WSL2 / Linux)

```bash
# LineageOS 23.2 (automatically fetches Neutron Clang and dependencies)
./build_lineage.sh d2x

# Stock One UI (automatically fetches Samsung CFP toolchain)
./build_kernel.sh d2xks
```

Generated flashable artifacts are located in `prebuilts/`:
* `boot_lineage_ksu_d2x.img` (Direct fastboot / dd boot image)
* `lineage-23.2_ksunext_d2x_signed.zip` (Recovery flashable archive)
* `N976N_KSUN_33355_v3.4.2_SUSFS_v1.5.5.tar` (Odin AP archive for Stock)

---

## 📱 Supported Devices

| Codename | Model | SoC | Tested OS |
| :--- | :--- | :--- | :--- |
| `d2x` / `d2xks` | Samsung Galaxy Note 10+ 5G (`SM-N976N`) | Exynos 9825 | LineageOS 23.2 / One UI 5.1 |
| `d1x` / `d1xks` | Samsung Galaxy Note 10 5G (`SM-N971N`) | Exynos 9825 | LineageOS 23.2 / One UI 5.1 |
| `d2` / `d2s` | Samsung Galaxy Note 10+ 4G (`SM-N975F`) | Exynos 9825 | LineageOS 23.2 / One UI 4.1 |
| `d1` | Samsung Galaxy Note 10 4G (`SM-N970F`) | Exynos 9825 | LineageOS 23.2 / One UI 4.1 |
| `beyond0lte` | Samsung Galaxy S10e (`SM-G970F`) | Exynos 9820 | LineageOS 23.2 / One UI 4.1 |
| `beyond1lte` | Samsung Galaxy S10 (`SM-G973F`) | Exynos 9820 | LineageOS 23.2 / One UI 4.1 |
| `beyond2lte` | Samsung Galaxy S10+ (`SM-G975F`) | Exynos 9820 | LineageOS 23.2 / One UI 4.1 |
| `beyondx` | Samsung Galaxy S10 5G (`SM-G977B`/`N`) | Exynos 9820 | LineageOS 23.2 / One UI 4.1 |

---

## 🛠️ Key Architectural Patches

* **KernelSU-Next v3.4.2 Ring 0 Hooks:** Direct manual syscall intercepts in `fs/exec.c`, `fs/open.c`, `fs/read_write.c`, `fs/stat.c`, `fs/namespace.c`, `kernel/sys.c`, `kernel/reboot.c`, and `security/selinux/hooks.c`, eliminating Kprobe and tracepoint instability on legacy 4.14 Samsung kernels.
* **Hardware Anti-Disconnect:** Neutralizes `unregister_gadget` and userspace `enable 0` calls in `drivers/usb/gadget/configfs.c`, preventing USB data dropouts during Android keyguard / lockscreen transitions.
* **Headless Panel Resilience:** Bypasses missing MIPI DSI panel ACK checks in `common_mipi_lcd.c`, enabling continuous headless operation without physical screens.
* **Modern Toolchain Compatibility:** Patched `tz_deploy_tzar.c` and Broadcom `bcmdhd` Wi-Fi makefiles for error-free compilation with Clang 24.0.0 and LLVM integrated assembler.

---

## 📜 Credits & Authorship

Created by **Antigravity** & **Q.S@RDOR**.

## ⚖️ License

This project is open-source software licensed under the [GNU General Public License v2.0](LICENSE).
