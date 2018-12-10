# Easy Life [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity) [![Open Source Love png1](https://badges.frapsoft.com/os/v1/open-source.png?v=103)](https://github.com/ellerbrock/open-source-badges/)

| master  | dev |
| ------------- | ------------- |
| [![Build Status](https://travis-ci.com/larromba/EasyLife.svg?branch=master)](https://travis-ci.com/larromba/EasyLife) | [![Build Status](https://travis-ci.com/larromba/EasyLife.svg?branch=dev)](https://travis-ci.com/larromba/EasyLife) |

## About
EasyLife [(app store)](...) is ...

## Installation from Source

### Dependencies
**SwiftGen**

`brew install swiftgen`

**SwiftLint**

`brew install swiftlint`

**Sourcery** *(testing only)*

`brew install sourcery`

**Carthage** 

`brew install carthage`

**Fastlane** *(app store snapshots only)*

`brew install fastlane`

### Build Instructions
This assumes you're farmiliar with Xcode and building iOS apps.

*Please note that you might need to change your app's bundle identifier and certificates to match your own.*

1. `carthage update`
2. open `EasyLife.xcodeproj`
3. select `EasyLife-Release` target
4. select your device from the device list
5. run the app on your phone

### Setting Up
On the simulator, ...

### Generating snapshots
```
cd <project root>
fastlane snapshot
cd screenshots
fastlane frameit silver
```

## How it works
...

## Licence
[![licensebuttons by-nc-sa](https://licensebuttons.net/l/by-nc-sa/3.0/88x31.png)](https://creativecommons.org/licenses/by-nc-sa/4.0) 

## Contact
larromba@gmail.com
