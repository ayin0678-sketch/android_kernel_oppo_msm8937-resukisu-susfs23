# OPPO A57 ReSukiSU + SUSFS 2.1.0

## Target

- Device: OPPO A57 / 16061
- SoC: Qualcomm MSM8940 / MSM8937
- Kernel: Linux 4.9.337
- ROM target: LineageOS 21
- Root implementation: ReSukiSU
- SUSFS version: 2.1.0

## Validation

This source snapshot has passed:

- kernel compilation;
- final vmlinux linking;
- Image.gz-dtb generation;
- AnyKernel3 ZIP packaging;
- TWRP installation;
- Android boot;
- manager recognition.

Boot and manager recognition are confirmed. Individual SUSFS
features have not all been exhaustively tested.

## ReSukiSU

Repository:

`https://github.com/ayin0678-sketch/ReSukiSU-A57-SUSFS21.git`

Pinned commit:

`85fd9faafb76143f6ff50b651fb852d06fd765b1`

## Build

```bash
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
OUT="$PWD/out/a57-resukisu-susfs21-full" \
JOBS=4 \
./build_a57_resukisu_susfs.sh
```

## Clone

```bash
git clone --recurse-submodules \
    -b lineage-21-resukisu-susfs21 \
    https://github.com/ayin0678-sketch/android_kernel_oppo_msm8937-resukisu-susfs21.git
```
