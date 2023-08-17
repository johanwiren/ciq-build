# ciq-build

Tools for Garmin ConnectIQ projects

## Requirements

* ConnectIQ SDK installation
* xpath
* expect
* jq

## Usage

Copy *ciq-build.mk* and *ciq-build.exp* to your project directory.

Add a *Makefile*

```Makefile
DEVELOPER_KEY = <path to your developer key>
APP_NAME = <Your app name>
DEFAULT_DEVICE=fenix7

include ./ciq-build.mk

run-default: run-on-$(DEFAULT_DEVICE)
```

### Make targets

* test: Runs tests
* build: Builds for default device
* release: Runs tests, exports and tags your build
