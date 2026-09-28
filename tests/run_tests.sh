#!/bin/bash
#
# Behaviour tests for swift-package-override. They run the tool against a throwaway project that depends on two
# throwaway git packages, all inside a temporary directory, so nothing outside it is touched.
#
# Requires git and a Swift toolchain (`swift package`).
#
# Usage: tests/run_tests.sh [path/to/swift-package-override]

set -u

TOOL="${1:-$(cd "$(dirname "$0")/.." && pwd)/swift-package-override}"
WORK="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/swift-package-override-tests.XXXXXX")" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

PROJECT="$WORK/project"
PACKAGE_DIR="Tuist"
CHECKOUTS="$PROJECT/$PACKAGE_DIR/.build/checkouts"

PASSED=0
FAILED=0
OUTPUT=""
STATUS=0

pass() {
	PASSED=$((PASSED + 1))
	echo "ok   $1"
}

fail() {
	FAILED=$((FAILED + 1))
	echo "FAIL $1"
	echo "$OUTPUT" | sed 's/^/     | /'
}

# Creates a git package with a 1.0.0 tag and one more commit on top, so an override differs from the pinned version.
make_package_repo() {
	local NAME="$1"; shift
	local DIR="$WORK/repos/$NAME"

	mkdir -p "$DIR/Sources/$NAME"
	cat > "$DIR/Package.swift" << PACKAGE
// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "$NAME", products: [.library(name: "$NAME", targets: ["$NAME"])], targets: [.target(name: "$NAME")])
PACKAGE
	echo 'public let version = 1' > "$DIR/Sources/$NAME/$NAME.swift"
	git -C "$DIR" init -q -b main
	git -C "$DIR" add -A
	git -C "$DIR" -c user.name=test -c user.email=test@example.com commit -q -m "1.0.0"
	git -C "$DIR" tag 1.0.0
	echo 'public let version = 2' > "$DIR/Sources/$NAME/$NAME.swift"
	git -C "$DIR" -c user.name=test -c user.email=test@example.com commit -q -a -m "After 1.0.0"
}

# Recreates the project with a resolved dependency graph. $1 is SWIFTPM_OVERRIDE_CONFIG__CREATE_CHECKOUTS_SYMLINK.
fresh_project() {
	local CREATE_CHECKOUTS_SYMLINK="$1"; shift

	rm -rf "$PROJECT"
	mkdir -p "$PROJECT/$PACKAGE_DIR" "$PROJECT/.swiftpm_override"
	cat > "$PROJECT/$PACKAGE_DIR/Package.swift" << PACKAGE
// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Project", dependencies: [
	.package(url: "file://$WORK/repos/PkgA", exact: "1.0.0"),
	.package(url: "file://$WORK/repos/PkgB", exact: "1.0.0"),
])
PACKAGE
	cat > "$PROJECT/.swiftpm_override/config" << CONFIG
SWIFTPM_OVERRIDE_CONFIG__VERSION=1
SWIFTPM_OVERRIDE_CONFIG__PACKAGE_DIR=$PACKAGE_DIR
SWIFTPM_OVERRIDE_CONFIG__BUILD_DIR=$PACKAGE_DIR/.build
SWIFTPM_OVERRIDE_CONFIG__CREATE_CHECKOUTS_SYMLINK=$CREATE_CHECKOUTS_SYMLINK
SWIFTPM_OVERRIDE_CONFIG__PROJECT_IMPORT_ON_OVERRIDE=0
SWIFTPM_OVERRIDE_CONFIG__SET_ENV_VAR=TEST_OVERRIDES
CONFIG
	(cd "$PROJECT/$PACKAGE_DIR" && swift package resolve > /dev/null 2>&1) || {
		echo "Error: failed to resolve the test project in $PROJECT" >&2
		exit 1
	}
}

# Runs the tool from the project root with TEST_OVERRIDES=$1. Sets OUTPUT and STATUS.
run_tool() {
	local OVERRIDES="$1"; shift
	OUTPUT=`cd "$PROJECT" && env TEST_OVERRIDES="$OVERRIDES" "$TOOL" "$@" 2>&1`
	STATUS=$?
}

is_override_link() {
	local NAME="$1"; shift
	[ -L "$CHECKOUTS/$NAME" ] && [ "`readlink "$CHECKOUTS/$NAME"`" == "../../Packages/$NAME" ]
}

make_package_repo PkgA
make_package_repo PkgB
SHA_A=`git -C "$WORK/repos/PkgA" rev-parse main`
SHA_B=`git -C "$WORK/repos/PkgB" rev-parse main`

echo "Testing $TOOL"

# With CREATE_CHECKOUTS_SYMLINK

fresh_project 1
run_tool "PkgA $SHA_A PkgB $SHA_B" set-env-var
if [ $STATUS -eq 0 ] && is_override_link PkgA && is_override_link PkgB; then
	pass "set links the checkout of every overridden package"
else
	fail "set links the checkout of every overridden package"
fi

run_tool "PkgA $SHA_A PkgB $SHA_B" check
if [ $STATUS -eq 0 ] && echo "$OUTPUT" | grep -q "Verification result: PASS"; then
	pass "check passes after set"
else
	fail "check passes after set"
fi

rm -f "$CHECKOUTS/PkgB"
run_tool "PkgA $SHA_A PkgB $SHA_B" check
if [ $STATUS -ne 0 ] && echo "$OUTPUT" | grep -q "Verification result: FAIL"; then
	pass "check fails when an override's checkouts symlink is missing"
else
	fail "check fails when an override's checkouts symlink is missing"
fi

ln -s "../../Packages/PkgA" "$CHECKOUTS/PkgB"
run_tool "PkgA $SHA_A PkgB $SHA_B" check
if [ $STATUS -ne 0 ] && echo "$OUTPUT" | grep -q "Verification result: FAIL"; then
	pass "check fails when an override's checkouts symlink points elsewhere"
else
	fail "check fails when an override's checkouts symlink points elsewhere"
fi

fresh_project 1
run_tool "PkgA $SHA_A PkgB $SHA_B" set-env-var
rm -f "$PROJECT/.swiftpm_override/manifest"
run_tool "PkgA $SHA_A PkgB $SHA_B" check
if [ $STATUS -ne 0 ] && echo "$OUTPUT" | grep -q "No manifest found"; then
	pass "check fails when the manifest is missing"
else
	fail "check fails when the manifest is missing"
fi

fresh_project 1
run_tool "PkgA $SHA_A Absent? 1.0.0" set-env-var
if [ $STATUS -eq 0 ] && grep -q "^PkgA " "$PROJECT/.swiftpm_override/manifest" && [ ! -e "$CHECKOUTS/Absent" ] && [ ! -L "$CHECKOUTS/Absent" ]; then
	pass "set skips an absent optional package when SWIFTPM_OVERRIDE_CONFIG__PACKAGE_DIR is set"
else
	fail "set skips an absent optional package when SWIFTPM_OVERRIDE_CONFIG__PACKAGE_DIR is set"
fi

# Without CREATE_CHECKOUTS_SYMLINK

fresh_project 0
run_tool "PkgA $SHA_A PkgB $SHA_B" set-env-var
if [ $STATUS -eq 0 ] && [ ! -L "$CHECKOUTS/PkgA" ] && [ ! -L "$CHECKOUTS/PkgB" ]; then
	pass "set creates no checkouts symlinks when the option is disabled"
else
	fail "set creates no checkouts symlinks when the option is disabled"
fi

run_tool "PkgA $SHA_A PkgB $SHA_B" check
if [ $STATUS -eq 0 ] && echo "$OUTPUT" | grep -q "Verification result: PASS" && ! echo "$OUTPUT" | grep -q "linked from checkouts"; then
	pass "check does not verify symlinks when the option is disabled"
else
	fail "check does not verify symlinks when the option is disabled"
fi

echo
echo "$PASSED passed, $FAILED failed"
[ $FAILED -eq 0 ]
