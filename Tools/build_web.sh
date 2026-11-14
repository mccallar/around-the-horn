#!/bin/sh
# Builds web/horn.wasm: the game's engine (HornEngine) and its JSON bridge (HornWeb),
# compiled to WebAssembly as a WASI reactor. Playing the web version needs none of this:
# the built file is committed. Run it after changing the engine or the bridge.
#
# Needs Swift 6.4.2 and its WebAssembly SDK, from swift.org (they need not be installed
# system-wide):
#   1. https://www.swift.org/install/ : download the Swift 6.4.2 toolchain for your
#      system and unpack it anywhere.
#   2. https://www.swift.org/documentation/articles/wasm-getting-started.html : install
#      the matching "swift-6.4.2-RELEASE_wasm" SDK, e.g.
#        <toolchain>/usr/bin/swift sdk install <URL of the 6.4.2 Wasm SDK> --checksum <its checksum>
#      or unpack the .artifactbundle into a directory of your choosing.
#   3. Point this script at them:
#        SWIFT_WASM_TOOLCHAIN=<toolchain>/usr/bin   (the directory holding `swift`)
#        SWIFT_WASM_SDKS=<directory holding swift-6.4.2-RELEASE_wasm.artifactbundle>
#      SWIFT_WASM_SDKS may be left out when the SDK was installed with `swift sdk install`.
#
#   SWIFT_WASM_TOOLCHAIN=... SWIFT_WASM_SDKS=... sh Tools/build_web.sh
set -eu

cd "$(dirname "$0")/.."

if [ -z "${SWIFT_WASM_TOOLCHAIN:-}" ] || [ ! -x "$SWIFT_WASM_TOOLCHAIN/swift" ]; then
    cat >&2 <<'EOF'
build_web.sh: set SWIFT_WASM_TOOLCHAIN to the bin directory of a Swift 6.4.2 toolchain
(the one that holds `swift`). Get the toolchain from https://www.swift.org/install/ and the
matching WebAssembly SDK (swift-6.4.2-RELEASE_wasm) as described in
https://www.swift.org/documentation/articles/wasm-getting-started.html, then run e.g.

  SWIFT_WASM_TOOLCHAIN=<toolchain>/usr/bin SWIFT_WASM_SDKS=<sdk directory> sh Tools/build_web.sh

See the top of this script for the details.
EOF
    exit 1
fi

SWIFT="$SWIFT_WASM_TOOLCHAIN/swift"
SDK="${SWIFT_WASM_SDK_NAME:-swift-6.4.2-RELEASE_wasm}"
SCRATCH="${TMPDIR:-/tmp}/horn-web-build"
set -- --swift-sdk "$SDK"
if [ -n "${SWIFT_WASM_SDKS:-}" ]; then set -- "$@" --swift-sdks-path "$SWIFT_WASM_SDKS"; fi

# A reactor: no main to run; the page calls _initialize, then the exports.
# -Osize and --strip-all keep the download down; --gc-sections drops what nothing calls.
"$SWIFT" build --disable-sandbox "$@" --scratch-path "$SCRATCH" -c release --product HornWeb \
    -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor \
    -Xswiftc -Osize \
    -Xlinker --strip-all -Xlinker --gc-sections

OUT="$SCRATCH/release/HornWeb.wasm"
OBJCOPY="$SWIFT_WASM_TOOLCHAIN/llvm-objcopy"
if [ -x "$OBJCOPY" ]; then
    # The linker keeps Swift's autolink notes; the browser has no use for them.
    "$OBJCOPY" --remove-section=.swift1_autolink_entries "$OUT" web/horn.wasm
else
    cp "$OUT" web/horn.wasm
fi
# wasm-opt (Binaryen) would shrink it further; it is not part of the toolchain, so it is
# used only if it happens to be on the PATH.
if command -v wasm-opt >/dev/null 2>&1; then
    if wasm-opt -Oz --detect-features web/horn.wasm -o "$SCRATCH/opt.wasm"; then
        cp "$SCRATCH/opt.wasm" web/horn.wasm
    else
        echo "wasm-opt failed; keeping the build as the linker wrote it" >&2
    fi
fi

BYTES=$(wc -c < web/horn.wasm | tr -d ' ')
echo "web/horn.wasm: $BYTES bytes ($((BYTES / 1024)) KB)"
