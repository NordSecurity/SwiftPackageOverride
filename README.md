# swift-package-override

`swift-package-override` is a tool to assist with performing ad-hoc Swift package dependency version overrides against Swift packages and Xcode projects. In an Xcode based development workflow, you can drag and drop local checkouts of a specific version of a package dependency to override it. `swift-package-override` provides a way to apply these kind of overrides which can be used in automated test workflows.

## Usage

1. `cd` into the root directory of the project to have a Swift package dependency override applied upon
2. `swift-package-override set LibtelioSwift v5.4.0` to apply an override
3. Perform testing
4. `swift-package-override check` to verify overrides in effect during testing
