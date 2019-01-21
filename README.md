# Easy Life [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity) [![Open Source Love png1](https://badges.frapsoft.com/os/v1/open-source.png?v=103)](https://github.com/ellerbrock/open-source-badges/)

| master  | dev |
| ------------- | ------------- |
| [![Build Status](https://travis-ci.com/larromba/EasyLife.svg?branch=master)](https://travis-ci.com/larromba/EasyLife) | [![Build Status](https://travis-ci.com/larromba/EasyLife.svg?branch=dev)](https://travis-ci.com/larromba/EasyLife) |

## About
EasyLife [(app store)](https://itunes.apple.com/app/id1229095589) is a simple app designed to streamline and focus your todo items by combining them all into 1 organized view.

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

### Generating snapshots
```
cd <project root>
fastlane snapshot
cd screenshots
fastlane frameit silver
```

## How it works
There are 3 sections in the todo list:
* Missed... - all items missed before today. missed items require attention to be rescheduled
* Today - all items for today
* Later - all items for a date after today. no stress

Todo items can recur, meaning they re-appear every x days. 

Todo items can be given a project. If a todo item is attached to a project, it appears higher in the list for the day it's scheduled, depending on the priority of the project

Marking recurring items as done moves them to a later date. Marking normal items as done moves them to the archive. Items can be undone in the archive view.

Todo items can block the progress of other todo items. Any blocking items must first be marked as done before the topmost item can be marked as done.

If a recurring item has been missed, rather than changing the recurring date, the item can be split, which creates a copy to be rescheduled, and automatically reschedules the original item at the next available recurring date

## Licence
[![licensebuttons by-nc-sa](https://licensebuttons.net/l/by-nc-sa/3.0/88x31.png)](https://creativecommons.org/licenses/by-nc-sa/4.0) 

## Contact
larromba@gmail.com
