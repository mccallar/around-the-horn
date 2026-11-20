#!/bin/sh
# Builds and runs a suite against a booted simulator WITHOUT `xcodebuild test`, which
# cannot allocate a pty inside a sandboxed shell — it fails with
#   "Failed to install or launch the test runner … Pseudo Terminal Setup Error … Operation not permitted"
# after a clean build, which reads as a broken suite and is not one. Outside the sandbox,
# plain `xcodebuild test -scheme <scheme> -destination '…'` works and is what CI runs.
#
#   sh Tools/run_tests.sh AroundTheHornTests           # the app suite
#   sh Tools/run_tests.sh HornEngine                   # the engine suite
#   sh Tools/run_tests.sh HornEngine RNGTests          # one XCTest class
#   NO_BUILD=1 sh Tools/run_tests.sh AroundTheHornTests   # skip build-for-testing
#
# NO_BUILD is only valid straight after a green build of the SAME scheme.
#
# ⚠️ Two invocations must not share a simulator: they fight over installing and launching
# and a passing test fails with a nonsense assertion. Use SIM_NAME to separate them.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROJ="$ROOT/AroundTheHorn.xcodeproj"
SCHEME=${1:?usage: run_tests.sh <scheme> [XCTestClass]}
ONLY=${2:-All}
SIM_NAME=${SIM_NAME:-iPhone 17 Pro}

UDID=${SIMULATOR_UDID:-$(xcrun simctl list devices booted -j \
  | python3 -c "import json,sys; ds=json.load(sys.stdin)['devices']; print(next(d['udid'] for v in ds.values() for d in v))" 2>/dev/null)}
[ -n "${UDID:-}" ] || { echo "no booted simulator (boot one, or set SIMULATOR_UDID)" >&2; exit 1; }

if [ -z "${NO_BUILD:-}" ]; then
  # ⚠️ `-disable-sandbox` IS A BUILD SETTING, NOT AN xcodebuild FLAG. Swift macros run
  # as a plugin server the outer sandbox refuses to spawn, and the failure reads as
  # "external macro implementation type … could not be found … produced malformed
  # response" on every `@Observable` in the app — which looks like a broken toolchain
  # and is a broken sandbox. It changes nothing outside this environment.
  xcodebuild build-for-testing -project "$PROJ" -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIM_NAME" \
    OTHER_SWIFT_FLAGS='$(inherited) -disable-sandbox' -quiet || exit 1
fi

DD=$(xcodebuild -project "$PROJ" -showBuildSettings -scheme "$SCHEME" 2>/dev/null \
  | awk '/ BUILD_DIR =/{print $3; exit}')
P="$DD/Debug-iphonesimulator"
PLAT=$(xcode-select -p)/Platforms/iPhoneSimulator.platform
export SIMCTL_CHILD_DYLD_LIBRARY_PATH="$P:$PLAT/Developer/usr/lib"
export SIMCTL_CHILD_DYLD_FRAMEWORK_PATH="$P:$PLAT/Developer/Library/Frameworks"

# THE APP SUITE IS HOSTED; THE ENGINE AND BOT SUITES ARE NOT, and that is the whole
# difference between the two branches. A hosted bundle rides inside AroundTheHorn.app with
# XCTest injected; a framework bundle is run by the platform's own `xctest` agent.
HOSTED="$P/AroundTheHorn.app/PlugIns/$SCHEME.xctest"
if [ -d "$HOSTED" ]; then
  xcrun simctl install "$UDID" "$P/AroundTheHorn.app" || exit 1
  export SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$PLAT/Developer/usr/lib/libXCTestBundleInject.dylib"
  export SIMCTL_CHILD_XCTestBundlePath="$HOSTED"
  exec xcrun simctl spawn "$UDID" "$P/AroundTheHorn.app/AroundTheHorn" -XCTest "$ONLY" "$HOSTED"
fi

# THE UI SUITE RUNS ITSELF. Its bundle rides in a RUNNER app that hosts XCTest, so —
# unlike the app suite — nothing is injected here, and both apps have to be installed.
RUNNER="$P/AroundTheHornUITests-Runner.app"
if [ "$SCHEME" = "AroundTheHornUITests" ] && [ -d "$RUNNER" ]; then
  xcrun simctl install "$UDID" "$P/AroundTheHorn.app" || exit 1
  xcrun simctl install "$UDID" "$RUNNER" || exit 1
  export SIMCTL_CHILD_XCTestBundlePath="$RUNNER/PlugIns/AroundTheHornUITests.xctest"
  exec xcrun simctl spawn "$UDID" "$RUNNER/AroundTheHornUITests-Runner" \
    -XCTest "$ONLY" "$SIMCTL_CHILD_XCTestBundlePath"
fi

BUNDLE="$P/${SCHEME}Tests.xctest"
[ -d "$BUNDLE" ] || BUNDLE="$P/$SCHEME.xctest"
[ -d "$BUNDLE" ] || { echo "no test bundle for $SCHEME under $P" >&2; exit 1; }
exec xcrun simctl spawn "$UDID" \
  "$PLAT/Developer/Library/Xcode/Agents/xctest" -XCTest "$ONLY" "$BUNDLE"
