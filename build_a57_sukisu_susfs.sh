#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${OUT:-$ROOT/out/a57-sukisu-susfs}"
DEFCONFIG="${DEFCONFIG:-lineageos_A57_defconfig}"
JOBS="${JOBS:-$(nproc)}"
KSU_COMMIT="b1d534bc41941b2c818d7a1a1dac341e4aabfc2d"
KSU_URL="https://github.com/SukiSU-Ultra/SukiSU-Ultra.git"
LOG="$OUT/build.log"

die() {
	echo "ERROR: $*" >&2
	exit 1
}

prepare_ksu() {
	if [[ ! -f "$ROOT/KernelSU/kernel/Makefile" ]]; then
		if [[ -e "$ROOT/KernelSU" ]] && [[ -n "$(ls -A "$ROOT/KernelSU" 2>/dev/null)" ]]; then
			die "KernelSU exists but is incomplete; move it aside and rerun."
		fi
		rmdir "$ROOT/KernelSU" 2>/dev/null || true
		git clone --filter=blob:none --no-checkout "$KSU_URL" "$ROOT/KernelSU"
		git -C "$ROOT/KernelSU" checkout --detach "$KSU_COMMIT"
	fi

	if [[ -n "$(git -C "$ROOT/KernelSU" status --porcelain 2>/dev/null)" ]]; then
		echo "KernelSU contains local Linux 4.9 compatibility fixes; continuing."
	fi
	if [[ "$(git -C "$ROOT/KernelSU" rev-parse HEAD)" != "$KSU_COMMIT" ]]; then
		git -C "$ROOT/KernelSU" fetch origin "$KSU_COMMIT"
		git -C "$ROOT/KernelSU" checkout --detach "$KSU_COMMIT"
	fi

	if [[ -L "$ROOT/drivers/kernelsu" ]]; then
		ln -sfn ../KernelSU/kernel "$ROOT/drivers/kernelsu"
	elif [[ -e "$ROOT/drivers/kernelsu" ]]; then
		die "drivers/kernelsu is not a symlink; move it aside and rerun."
	else
		ln -s ../KernelSU/kernel "$ROOT/drivers/kernelsu"
	fi
}

find_clang_bin() {
	local candidate
	for candidate in \
		"${CLANG_BIN:-}" \
		"${TOOLCHAIN:-}/bin" \
		"$ROOT/toolchain/clang/bin" \
		"$ROOT/toolchains/clang/bin" \
		"$ROOT/clang/bin" \
		"$HOME/toolchains/clang/bin" \
		"$HOME/clang/bin"; do
		[[ -n "$candidate" && -x "$candidate/clang" ]] && {
			echo "$candidate"
			return 0
		}
	done
	command -v clang >/dev/null 2>&1 && dirname "$(command -v clang)"
}

find_cross_prefix() {
	local prefix candidate
	if [[ -n "${CROSS_COMPILE:-}" && -x "${CROSS_COMPILE}gcc" ]]; then
		echo "$CROSS_COMPILE"
		return 0
	fi
	for candidate in \
		"$ROOT/toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-" \
		"$ROOT/toolchains/aarch64-linux-android-4.9/bin/aarch64-linux-android-" \
		"$ROOT/aarch64-linux-android-4.9/bin/aarch64-linux-android-" \
		"$HOME/toolchains/aarch64-linux-android-4.9/bin/aarch64-linux-android-"; do
		[[ -x "${candidate}gcc" ]] && {
			echo "$candidate"
			return 0
		}
	done
	for prefix in aarch64-linux-android- aarch64-linux-gnu-; do
		command -v "${prefix}gcc" >/dev/null 2>&1 && {
			command -v "${prefix}gcc" | sed 's/gcc$//'
			return 0
		}
	done
	return 1
}

prepare_ksu
[[ -f "$ROOT/arch/arm64/configs/$DEFCONFIG" ]] || die "missing $DEFCONFIG"

mkdir -p "$OUT"
CLANG_DIR="$(find_clang_bin || true)"
CROSS_PREFIX="$(find_cross_prefix || true)"

MAKE_ARGS=(ARCH=arm64 O="$OUT")
if [[ -n "$CLANG_DIR" && -n "$CROSS_PREFIX" ]]; then
	export PATH="$CLANG_DIR:$(dirname "$CROSS_PREFIX"):$PATH"
	MAKE_ARGS+=(LLVM=1 LLVM_IAS=1 CROSS_COMPILE="$CROSS_PREFIX" CLANG_TRIPLE=aarch64-linux-gnu-)
	echo "Compiler: $($CLANG_DIR/clang --version | head -1)"
elif [[ -n "$CROSS_PREFIX" ]]; then
	export PATH="$(dirname "$CROSS_PREFIX"):$PATH"
	MAKE_ARGS+=(CROSS_COMPILE="$CROSS_PREFIX")
	echo "Compiler: $(${CROSS_PREFIX}gcc --version | head -1)"
else
	die "No ARM64 toolchain found. Set CROSS_COMPILE and optionally CLANG_BIN."
fi

export KBUILD_BUILD_USER="${KBUILD_BUILD_USER:-a57}"
export KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST:-debian}"

echo "Defconfig: $DEFCONFIG"
echo "Output:    $OUT"
make -C "$ROOT" "${MAKE_ARGS[@]}" "$DEFCONFIG"
make -C "$ROOT" "${MAKE_ARGS[@]}" olddefconfig

{
	make -C "$ROOT" -j"$JOBS" "${MAKE_ARGS[@]}" Image.gz-dtb
} 2>&1 | tee "$LOG"

IMAGE="$OUT/arch/arm64/boot/Image.gz-dtb"
[[ -s "$IMAGE" ]] || die "build finished without Image.gz-dtb"

cp -f "$IMAGE" "$ROOT/AnyKernel3/Image.gz-dtb"
if command -v zip >/dev/null 2>&1; then
	PACKAGE="$OUT/SukiSU-SUSFS-v1.5.5-OPPO-A57.zip"
	(
		cd "$ROOT/AnyKernel3"
		zip -qr9 "$PACKAGE" . -x '.git/*' 'README.md'
	)
	echo "Package: $PACKAGE"
fi

echo "Image:   $IMAGE"
echo "Log:     $LOG"
