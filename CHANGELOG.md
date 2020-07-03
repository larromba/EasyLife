# Changelog

## v3.0.0 (TBC)
    minor bug fixes and improvements
    fix: coredata threading issues
    added focus mode

## v2.0.3 (30/07/2019)
    fixed ordering bug in later section
    added 'bi-monthly' option

## v2.0.2 (09/04/2019)
    fixed crash when selecting project

## v2.0.1 (01/02/2019)
    minor bug fixes and improvements

## v2.0.0 (21/01/2019) (Free)
    huge code refactor
    open sourced code
    pressing back on new item with changes by mistake now asks if you want to save the changes

## v1.5.0 (25/02/2018)
    Can now split recurring items and reschedule them without affecting the recurring date
    Version moved to lower bottom left
    Added 'blocked by' feature. Items can't be set to done when blocked by another item
    Fix: archive view keyboard bugs
    Fix: archive view search bugs
    Added clear all in archive view
    Added colour animation to 'Youre done for now'
    Added note indicator to each item in the plan view
    Improved later section ordering
    Added new button to choose different date pickers in the details view

## v1.4.0 (24/01/2018)
    Added time indicator to later cells
    Fixed projects priority bug
    updated archive headers to be by alphabet rather than date

## v1.3.1 (07/11/2017)
    Fixed bug when selecting 'later' for an event far in the past
    Improved ordering for 'missed' and 'today' sections

## v1.3.0 (12/10/2017)
    New projects view

## v1.2.0 (07/06/2017)
    Improved ordering in later section
    New archive view
    New icon for items recorded without a date

## v1.1.0 (31/05/2017)
    New done message when there are no missed items, or items today
    New badge number that shows number of missed & today items
    Added small icon to recurring events
    Added version number

## v1.0.0 (23/04/2017) (Tier: 1)
    Things you missed...
    Things you want to do today
    Things you will do later...
    Items have: title, date, repeats, notes

# AppStore

SKU: 421042017
Apple ID: 1229095589

# Future Work

3.0.0:
long press on cell: make tomorrow
holiday mode
add none selection to project picker
add clear button to blocked list
search app & check protocols are being used (not direct references)
fix initial load flickers: plan table fade on reload
simple date picker not clearing date
project needs empty selection
move coredata to new repo
update libs

3.1.0:
BUG: missed doesnt change. Split then done doesnt work.
BUG: typing in notes is wierd
BUG: later done if recurring doesnt work
BUG: app becomes active not always updating

Minor:
plancell ui tests rather than ui tests in each test class?
use plan cell everywhere?
refactor out uitableviewaction from tests?

Future:
short instructional video
how to update badge at midnight?
add noise when items done 
siri integration
are project buttons in weird order?
revisit action rules for sections
should done recurring items add copy to archive?
