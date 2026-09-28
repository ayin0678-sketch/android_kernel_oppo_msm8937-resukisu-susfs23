# OPPO A57 (MSM8937 / 16061) Kernel - ReSukiSU main + SuSFS 2.3 + BPF 5.4

Tested and verified kernel for OPPO A57 running Android 16 (A16) GSI with root, hide, and modern eBPF networking support.

## Feature Overview

| Component | Version / Status | Description |
|---|---|---|
| **Base Kernel** | Linux 4.9.337 (LineageOS) | Built with Proton Clang 13 toolchain |
| **Target Device** | OPPO A57 / A57m / A57t | Project 16061, Qualcomm MSM8937 / MSM8940 |
| **ReSukiSU** | `main` (`v4.2.0-rc3`, code 35185) | Latest upstream with non-GKI Linux 4.9 crash fixes |
| **SuSFS** | `v2.3.0` | Full inline hooks, open_redirect, mount hide, kstat spoof |
| **BPF** | Backported Linux 5.4 BPF | Supports Android 16 GSI bpfloader and netbpfload |
| **uname Spoof** | Dynamic process spoofing | Spoofs Linux 5.4.0 for `bpfloader`, `netbpfload`, `netd` |
| **Device Trees** | 3 DTBs bundled | Fully compatible with all OPPO A57 hardware revisions |

## Verified Working State
- **Boots cleanly** past the boot animation / second screen into Android 16 GSI launcher.
- **Root access** verified with ReSukiSU / KernelSU managers.
- **SuSFS 2.3** confirmed fully active without EDL/9008 crashes.

## Releases
- Flashable AnyKernel3 package available under GitHub Releases: [v2.3.0-bpf-resukisu-main](https://github.com/ayin0678-sketch/android_kernel_oppo_msm8937-resukisu-susfs23/releases/tag/v2.3.0-bpf-resukisu-main)
