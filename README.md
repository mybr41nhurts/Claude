# Weight Journey

A native SwiftUI iPhone app for tracking weight loss: weigh-ins (including
back-dated historic entries), BMI, trends, a goal broken into milestones,
and a forecasted goal date based on your recent trend.

## Features

- **Log weight** — quick entry for today, or any past date, so you can
  back-fill history.
- **BMI** — computed automatically from your latest weight and height, with
  the standard WHO category (Underweight / Normal / Overweight / Obese).
- **Trends** — a chart of every weigh-in with a smoothed 7-entry moving
  average, filterable by 1W/1M/3M/6M/1Y/All.
- **Goals & milestones** — set a starting weight and a goal weight; it's
  automatically split into evenly-spaced milestones (you choose how many),
  each marked achieved as soon as a logged weight crosses it.
- **Forecast** — a linear-regression projection over your recent weigh-ins
  estimates the date you'll hit your goal at your current pace, plotted as
  a dashed line on the trend chart.
- All data is stored locally on-device with SwiftData — nothing leaves
  your phone.

## Requirements

- A Mac with Xcode 15 or later (SwiftData and Swift Charts require iOS 17+).
- An iPhone (or the iOS 17+ Simulator) to run it on.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the
  `.xcodeproj` from `project.yml` (the project file itself isn't checked
  in, since XcodeGen regenerates it deterministically):

  ```sh
  brew install xcodegen
  ```

## Build & run

```sh
cd Claude   # repo root, where project.yml lives
xcodegen generate
open WeightJourney.xcodeproj
```

Then in Xcode:

1. Select the `WeightJourney` scheme.
2. Pick your iPhone (or a simulator) as the run destination.
3. If running on a physical device, set your Team under
   *Signing & Capabilities* (the project uses automatic signing).
4. Press Run.

### If you'd rather not install XcodeGen

Create a new Xcode project (App template, SwiftUI interface, Swift
language, iOS 17+ deployment target, and check "Use SwiftData"), then drag
the `WeightJourney/` folder's `.swift` files and `Assets.xcassets` into it,
replacing the generated placeholders.

## Project layout

```
project.yml                  XcodeGen project spec
WeightJourney/
  WeightJourneyApp.swift     App entry point, SwiftData container
  RootView.swift             Onboarding vs. main app switch
  Models/                    SwiftData models (WeightEntry, UserProfile,
                              WeightGoal, Milestone)
  Support/                   Unit conversion, BMI, forecast engine,
                              milestone generation — plain Swift, unit-testable
  Views/                     SwiftUI screens (Dashboard, Trends, Goals,
                              History, Settings, Onboarding, Log Weight)
```

## Notes

- This was built and reviewed in a Linux cloud environment without an
  Xcode/Swift toolchain available, so it has **not** been compiled or run
  in the Simulator. The code follows standard SwiftUI/SwiftData/Swift
  Charts APIs (iOS 17 target), but please build it in Xcode and try the
  golden path (onboarding → log a weight → check Dashboard/Trends/Goals)
  before relying on it; file an issue with the build error if Xcode
  reports one and it can be fixed from here.
- Change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to your own reverse-DNS
  identifier before running on a real device with your Apple ID.
- The app ships without a custom app icon — add one in
  `WeightJourney/Assets.xcassets/AppIcon.appiconset` whenever you're ready.
