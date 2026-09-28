## 0.7.0
- Create a checkouts symlink for every overridden package, not only the last one, with `SWIFTPM_OVERRIDE_CONFIG__CREATE_CHECKOUTS_SYMLINK`
- Verify the checkouts symlinks in `check` with `SWIFTPM_OVERRIDE_CONFIG__CREATE_CHECKOUTS_SYMLINK`
- Fail `check` when the manifest is missing
- Fix skipping an absent optional package override when `SWIFTPM_OVERRIDE_CONFIG__PACKAGE_DIR` is set
- Add behaviour tests in `tests/run_tests.sh`

## 0.6.3
- Fetch overridden revisions missing from the SwiftPM repository cache in `set` command

## 0.6.2
- Add missing command descriptions in `help` command

## 0.6.1
- Remove command path prefix in `help` command

## 0.6.0
- Omit repetitive output of commit hashes in `show` command
- Add `version` command
- Add `all` aggregate target in Xcode project

## 0.5.0
- Add `SWIFTPM_OVERRIDE_CONFIG__CREATE_CHECKOUTS_SYMLINK` config option
- Add `SWIFTPM_OVERRIDE_CONFIG__PROJECT_IMPORT_ON_OVERRIDE` config option
- Add `project-import` command
- Improve usage documentation in `README.md`
- Add Xcode project for installation

## 0.4.0
- Add support for Xcode version switching with `.xcode-version` and `xcodes`

## 0.3.0
- Add `status-env-var` command

## 0.2.2
- Improve `check` error logging for better clarity on failure condition and causes
- Fix optional package override skip logic when matched case insensitively

## 0.2.1
- Fix optional package overrides when `SWIFTPM_OVERRIDE_CONFIG__PACKAGE_DIR` is set

## 0.2.0
- Add optional package override using question mark

## 0.1.0
- Initial release
