# swift-package-override

`swift-package-override` is a tool to assist with performing ad-hoc Swift package dependency version overrides against Swift packages and Xcode projects. In an Xcode based development workflow, you can drag and drop local checkouts of a specific version of a package dependency to override it. `swift-package-override` provides a way to apply these kind of overrides which can be used in automated test workflows.

## Usage

1. `cd` into the root directory of the project to have a Swift package dependency override applied upon
2. `swift-package-override set LibtelioSwift v5.4.0` to apply an override
3. Perform testing
4. `swift-package-override check` to verify overrides in effect during testing

For full usage information, run `swift-package-override help`

## Configuration

`swift-package-override` is configured using configuration files in a `.swiftpm_override` directory at the root level of a project:

```
├── .swiftpm_override
│   ├── config
│   └── projects
```

### `.swiftpm_override/config`

Configuration opions are set as POSIX sh variable assignments. E.g.

```
SWIFTPM_OVERRIDE_CONFIG__VERSION=1
```

#### `SWIFTPM_OVERRIDE_CONFIG__VERSION`


`SWIFTPM_OVERRIDE_CONFIG__VERSION` must be set to `1`, indicating the version of the configuration conventions being used.

#### `SWIFTPM_OVERRIDE_CONFIG__PACKAGE_DIR`

`SWIFTPM_OVERRIDE_CONFIG__PACKAGE_DIR` is used to identify the directory which contains the `Package.swift` file containing the project Swift package dependencies. By default, the `Package.swift` file is expected to be found in the root level of the project. If it is located in a sub directory/package, it should be configured here.

#### `SWIFTPM_OVERRIDE_CONFIG__BUILD_DIR`

`SWIFTPM_OVERRIDE_CONFIG__BUILD_DIR` is used to specify a custom build directory (normally `.build`) produced by execution of `swift` commands. It must be set to perform package override verification using the `check` command, after execution of a build or test `swift` command.

#### `SWIFTPM_OVERRIDE_CONFIG__DERIVEDDATA_DIR`

`SWIFTPM_OVERRIDE_CONFIG__DERIVEDDATA_DIR` is used to specify a custom derived data directory produced by execution of `xcodebuild` commands. It must be set to perform package override verification using the `check` command, after execution of a build or test `xcodebuild` command.

#### `SWIFTPM_OVERRIDE_CONFIG__CREATE_PACKAGE_WORKSPACE`

`SWIFTPM_OVERRIDE_CONFIG__CREATE_PACKAGE_WORKSPACE` is disabled by default. Enable it by setting a value of `1`. This is required for Swift package based projects which do not have Xcode project or workspaces, but which have builds/tests performed against them using `xcodebuild`.

#### `SWIFTPM_OVERRIDE_CONFIG__CREATE_CHECKOUTS_SYMLINK`

`SWIFTPM_OVERRIDE_CONFIG__CREATE_CHECKOUTS_SYMLINK` is disabled by default. Enable it by setting a value of `1`. This is is required for use of `swift-package-override` with Tuist and dependencies are defined using the `Tuist/Package.swift` file. If package dependencies are specified using a `Package.swift` file in a different location, this option can be left as disabled.

#### `SWIFTPM_OVERRIDE_CONFIG__SET_ENV_VAR`

`SWIFTPM_OVERRIDE_CONFIG__SET_ENV_VAR` must be set to the name of the environment variable which should contain the list of package overrides (as package name, Git ref pairs separated by spaces) `set-env-var` and `status-env-var` commands.

#### `SWIFTPM_OVERRIDE_CONFIG__PROJECT_IMPORT_ON_OVERRIDE`

`SWIFTPM_OVERRIDE_CONFIG__PROJECT_IMPORT_ON_OVERRIDE` is enabled by default. If it is disabled, Xcode projects or workspaces listed in `.swiftpm_override/projects` will not have package overrides imported into them when `swift-package-override` `set` or `set-env-var` commands are run. This is useful for projects which are performing Xcode project or workspace generation using separate tools (e.g. xcodegen, or Tuist). After Xcode project or workspace generation has been performed using another tool, an explicit project import can be performed using `swift-package-override project-import`.

### `.swiftpm_override/projects`

This file should contain the paths to xcodeproj bundles which should have package overrides applied to them. Each path should be followed by a LF.
