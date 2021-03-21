# Easy Life [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://img.shields.io) [![Open Source Love png1](https://badges.frapsoft.com/os/v1/open-source.png?v=103)](https://github.com/ellerbrock/open-source-badges/)

| master  | dev |
| ------------- | ------------- |
| [![Build Status](https://travis-ci.com/larromba/EasyLife.svg?branch=master)](https://travis-ci.com/larromba/EasyLife) | [![Build Status](https://travis-ci.com/larromba/EasyLife.svg?branch=develop)](https://travis-ci.com/larromba/EasyLife) |

## About
EasyLife [(app store)](https://itunes.apple.com/app/id1229095589) is a simple app designed to streamline and focus your todo items by combining them all into 1 organised view.

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

1. `carthage update --platform iOS`
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
* Missed... - all items before today. They come first as they require attention to be rescheduled
* Today - all items for today.
* Later - all items for a date after today. They come last as they're not important in the present moment.

There are 4 toolbar buttons (from left to right):
* Archive - a list of all done items. They can be undone from this view
* Projects - a list of all projects. Todo items can be assigned a project. Based on the project's priority, it appears higher or lower in its section.
* Focus Mode - displays all 'Today' items one at a time, based on their order. There is a timer to facilitate focusing in bursts of time.
* New Item - creates a new todo item.

Swiping left on each item displays some actions:
* Delete - deletes an item
* Done - finishes an item
* Later - if the item is non-recurring, the date is deleted. If the item is recurring, it's rescheduled to the next date
* Split (recurring items only) - Recurring items can be split in two. The original original item is rescheduled to the next date, and an independent copy is kept in the current section. This allows you to reschedule a recurring item without affecting the original recurring date.
* In 'Focus Mode', only 'Done' will be displayed.

General:
* Items can block the progress of other items. Blocking items must be done before blocked items. Their blocking status is represented by:
    - a red indicator: the item is blocked by something
    - a grey indicator: the item is blocking something else
    - a red + grey indicator: the item is both blocked by something and blocking something else
* Long-pressing missed items brings up useful shortcuts
* Triple-tapping the plan view puts the app into 'holiday mode'

Tips:
* Check the app every morning to see an overview of your day. Make this a habit.
* When you have a thought, record it straight away. Don't worry about setting a date. You can reschedule it later. Make this a habit.
* Think about key areas of your life and set them as projects. Update their priorities based on what needs your attention in the present. This will change over time.
* Before using 'Focus Mode', organise the 'Today' section.

## Contributing
It might help to read this [architecture and style guide](https://github.com/larromba/ios-code-architecture) before contributing.

## Licence
[![licensebuttons by-nc-sa](https://licensebuttons.net/l/by-nc-sa/3.0/88x31.png)](https://creativecommons.org/licenses/by-nc-sa/4.0) 

## Contact
Use [this form](http://developer.larhythmix.com/contact).
