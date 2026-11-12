# OPPO A57 BakaSU + SUSFS 2.4.0

## Target

- Device: OPPO A57 / 16061
- SoC: Qualcomm MSM8940 / MSM8937
- Kernel: Linux 4.9.337
- ROM target: LineageOS 21
- Root implementation: [BakaSU](https://github.com/Baka-SU/BakaSU) branch `main`
- SUSFS version: v2.4.0 NON-GKI
- Hook mode: `CONFIG_KSU_SUSFS` (SUSFS inline hook)

## What changed from the 2.1 snapshot

The kernel build clones BakaSU `main` and applies `patches/bakasu-susfs24.patch`
so the priority-uid filter command is available. SUSFS v2.4.0 is wired through
the existing 4.9 call sites. The sdcard fsnotify watch keeps the 4.9
`handle_event` API, and the mount-id sentinel used by `fs/namespace.c` is kept.

The previous ReSukiSU + SUSFS 2.1.0 snapshot of this branch booted and was
recognized by the manager. This 2.4 update still has to be confirmed by the
GitHub Action build and a device flash.

## Build

```bash
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
OUT="$PWD/out/a57-bakasu-susfs" \
JOBS=4 \
./build_a57_resukisu_susfs.sh
```

`KSU_COMMIT` overrides the BakaSU ref. The default is `main`.

## Clone

```bash
git clone -b lineage-21-resukisu-susfs23 \
    https://github.com/ayin0678-sketch/android_kernel_oppo_msm8937-resukisu-susfs23.git
```
