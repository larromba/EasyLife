# Changelog

## v3.0.2 (03/12/2020)
    fixed date picker appearance in iOS 14.0

## v3.0.1 (29/11/2020)
    fixed app not refreshing on rentry
    fixed typing in notes

## v3.0.0 (09/07/2020)
    fixed coredata threading issues
    fixed table reload flickers
    minor bug fixes and improvements
    added focus mode
    added holiday mode
    added unblock button 

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

3.0.3:
BUG: missed doesnt change. Split then done doesnt work.
BUG: later done if recurring doesnt work

3.0.4:
move coredata to new repo

3.1.0:
skip in focus mode?
add move to tomoorrow options to today section

3.2.0:
should done recurring items add copy to archive?
search bars in all views (especially blocked)?

Future Minor:
use plan cell everywhere?
    - if so, plancell ui tests rather than ui tests in each test class?
refactor out uitableviewaction from tests?
find better way of testing tableview cell order
rename some things to services? 
_ = try await --> try await
throwErrorOnMain

Future Major:
short instructional video?
how to update badge at midnight?
add noise when items done ?
siri integration?
are project buttons in weird order?
revisit action rules for sections?

Far future:
make work on mac - need to use CoreData with iCloud?
