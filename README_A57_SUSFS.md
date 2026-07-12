# OPPO A57 SukiSU + SUSFS v1.5.5 completion patch

Target tree: `XuexGao/android_kernel_oppo_msm8937`, branch
`lineage-21-sukisu-susfs`.

This patch completes the legacy SUSFS v1.5.5 transport and process hook path
before any SUSFS v2.2.0 backport is attempted.  It adds:

- OPPO A57 (`16061`, MSM8940/MSM8937) defconfig support;
- the missing `setresuid` call into SukiSU's SUSFS process handler;
- correct reboot-supercall early-return handling;
- a legacy SUSFS v1.5.5 `prctl` dispatcher;
- a reboot-to-v1.5.5 parameter bridge;
- the legacy auto-mount and try-umount Kconfig options;
- an A57 AnyKernel3 target;
- an A57 Debian build script which pins SukiSU commit `b1d534bc`.

SUSFS v2-only features (`sus_path_loop`, `sus_map`, AVC spoofing and the
sdcard monitor) are intentionally not advertised as implemented.  In
particular `CONFIG_KSU_SUSFS_SUS_MAP` is disabled for A57.

## Apply

```bash
cd ~/kernel/source/android_kernel_oppo_msm8937
git apply --check OPPO_A57_SukiSU_SUSFS_v1.5.5_complete.patch
git apply OPPO_A57_SukiSU_SUSFS_v1.5.5_complete.patch
chmod +x build_a57_sukisu_susfs.sh
```

## Build

If the toolchains are stored in the usual tree locations, run:

```bash
./build_a57_sukisu_susfs.sh
```

The script searches for clang and AArch64 GCC under `toolchain/`,
`toolchains/`, the repository root and `$HOME/toolchains`.  Explicit paths can
be supplied when needed:

```bash
CLANG_BIN=/path/to/clang/bin \
CROSS_COMPILE=/path/to/aarch64-linux-android-4.9/bin/aarch64-linux-android- \
./build_a57_sukisu_susfs.sh
```

For GCC-only compilation:

```bash
CROSS_COMPILE=/path/to/aarch64-linux-android-4.9/bin/aarch64-linux-android- \
CLANG_BIN= \
./build_a57_sukisu_susfs.sh
```

Outputs are placed in:

```text
out/a57-sukisu-susfs/arch/arm64/boot/Image.gz-dtb
out/a57-sukisu-susfs/SukiSU-SUSFS-v1.5.5-OPPO-A57.zip
out/a57-sukisu-susfs/build.log
```

The patch intentionally stops at a completed v1.5.5 implementation.  A real
v2.2.0 backport is a separate patch series because upstream keeps Linux 4.9 on
v1.5.5.
