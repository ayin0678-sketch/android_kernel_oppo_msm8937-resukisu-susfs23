#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${OUT:-$ROOT/out/a57-bakasu-susfs}"
DEFCONFIG="${DEFCONFIG:-lineageos_A57_defconfig}"
JOBS="${JOBS:-$(nproc)}"
KSU_COMMIT="${KSU_COMMIT:-main}"
KSU_URL="https://github.com/Baka-SU/BakaSU.git"
KSU_DIR="$ROOT/BakaSU"
KSU_PATCH="$ROOT/patches/bakasu-susfs24.patch"
LOG="$OUT/build.log"

die() {
	echo "ERROR: $*" >&2
	exit 1
}

prepare_ksu() {
	echo "Preparing BakaSU source..."
	if [[ ! -d "$KSU_DIR/.git" ]] && [[ ! -f "$KSU_DIR/.git" ]]; then
		rm -rf "$KSU_DIR"
		echo "Cloning BakaSU from $KSU_URL..."
		git clone "$KSU_URL" "$KSU_DIR"
	else
		git -C "$KSU_DIR" remote set-url origin "$KSU_URL" 2>/dev/null || true
	fi

	git -C "$KSU_DIR" fetch origin --tags
	git -C "$KSU_DIR" reset --hard
	git -C "$KSU_DIR" clean -fd
	if [[ "$KSU_COMMIT" == "main" ]]; then
		git -C "$KSU_DIR" checkout --detach origin/main
	else
		git -C "$KSU_DIR" checkout --detach "$KSU_COMMIT"
	fi

	if [[ -s "$KSU_PATCH" ]]; then
		git -C "$KSU_DIR" apply --check "$KSU_PATCH"
		git -C "$KSU_DIR" apply "$KSU_PATCH"
	else
		die "missing BakaSU SUSFS 2.4 patch: $KSU_PATCH"
	fi

	rm -rf "$ROOT/drivers/kernelsu"
	ln -s ../BakaSU/kernel "$ROOT/drivers/kernelsu"

	echo "BakaSU source: $(git -C "$KSU_DIR" rev-parse HEAD)"
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
	if [[ -n "${CROSS_COMPILE:-}" ]]; then
		if [[ -x "${CROSS_COMPILE}gcc" ]] || [[ -x "${CROSS_COMPILE}ld" ]] || command -v "${CROSS_COMPILE}gcc" >/dev/null 2>&1 || command -v "${CROSS_COMPILE}ld" >/dev/null 2>&1; then
			echo "$CROSS_COMPILE"
			return 0
		fi
	fi
	for candidate in \
		"$ROOT/toolchain/clang/bin/aarch64-linux-gnu-" \
		"$ROOT/toolchains/clang/bin/aarch64-linux-gnu-" \
		"$ROOT/toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-" \
		"$ROOT/toolchains/aarch64-linux-android-4.9/bin/aarch64-linux-android-" \
		"$ROOT/aarch64-linux-android-4.9/bin/aarch64-linux-android-" \
		"$HOME/toolchains/aarch64-linux-android-4.9/bin/aarch64-linux-android-"; do
		if [[ -x "${candidate}gcc" ]] || [[ -x "${candidate}ld" ]]; then
			echo "$candidate"
			return 0
		fi
	done
	for prefix in aarch64-linux-gnu- aarch64-linux-android-; do
		if command -v "${prefix}gcc" >/dev/null 2>&1 || command -v "${prefix}ld" >/dev/null 2>&1; then
			echo "$prefix"
			return 0
		fi
	done
	return 1
}

prepare_ksu
[[ -f "$ROOT/arch/arm64/configs/$DEFCONFIG" ]] || die "missing $DEFCONFIG"

mkdir -p "$OUT"
CLANG_DIR="$(find_clang_bin || true)"
CROSS_PREFIX="$(find_cross_prefix || true)"

find_arm32_prefix() {
    local prefix candidate

    if [[ -n "${CROSS_COMPILE_ARM32:-}" ]]; then
        if [[ -x "${CROSS_COMPILE_ARM32}gcc" ]] || [[ -x "${CROSS_COMPILE_ARM32}ld" ]] || command -v "${CROSS_COMPILE_ARM32}gcc" >/dev/null 2>&1 || command -v "${CROSS_COMPILE_ARM32}ld" >/dev/null 2>&1; then
            echo "$CROSS_COMPILE_ARM32"
            return 0
        fi
    fi

    for candidate in \
        "$ROOT/toolchain/clang/bin/arm-linux-gnueabi-" \
        "$ROOT/toolchains/clang/bin/arm-linux-gnueabi-" \
        "$ROOT/toolchain/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-" \
        "$ROOT/toolchains/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-" \
        "$ROOT/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-" \
        "$HOME/toolchains/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"; do
        if [[ -x "${candidate}gcc" ]] || [[ -x "${candidate}ld" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    for prefix in \
        arm-linux-gnueabi- \
        arm-linux-gnueabihf- \
        arm-linux-androideabi-; do
        if command -v "${prefix}gcc" >/dev/null 2>&1 || command -v "${prefix}ld" >/dev/null 2>&1; then
            echo "$prefix"
            return 0
        fi
    done

    return 1
}

ARM32_PREFIX="$(find_arm32_prefix || true)"

[[ -n "$ARM32_PREFIX" ]] ||
    die "No ARM32 compiler found. Set CROSS_COMPILE_ARM32."

MAKE_ARGS=(
    ARCH=arm64
    O="$OUT"
    CROSS_COMPILE_ARM32="$ARM32_PREFIX"
)
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
	PACKAGE="$OUT/BakaSU-SUSFS-v2.4.0-OPPO-A57.zip"
	(
		cd "$ROOT/AnyKernel3"
		zip -qr9 "$PACKAGE" . -x '.git/*' 'README.md'
	)
	echo "Package: $PACKAGE"
fi

echo "Image:   $IMAGE"
echo "Log:     $LOG"
