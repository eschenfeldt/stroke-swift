# StrokeModel #

This package implements a Swift 4.2 version of the stroke pre-hospital triage model at https://github.com/aymannnn/stroke, extended to allow comparisons of multiple primary stroke centers.

### API ###

The StrokeModel package exposes the following classes:

- `StrokeModel`, an encapsulating class that provides public functions for running the model
- `Inputs`, a class containing all of the direct model inputs, and `Sex`, an enum for patient sex (one of the model inputs)
- `StrokeCenter`, an open class storing information about a stroke center under consideration, including travel time(s)
- `SingleRunResults` and `MultiRunResults`, encapsulating model outputs, along with the struct `Strategy` defining the possible triage decisions
- `Race`, an enum namespace encapsulating several enums and the function `scoreFrom` for use in computing the [RACE score](https://www.mdcalc.com/rapid-arterial-occlusion-evaluation-race-scale-stroke), and static functions `toNIHSS` and `fromNIHSS` for converting between RACE and [NIHSS](https://www.mdcalc.com/nih-stroke-scale-score-nihss).

The simplest way to run the model is to use the optional initializer

```swift
Inputs(sex: Sex, age: Int, race: Double, timeSinceSymptoms: Double,
       primaryTimes: [Double], transferTimes: [Double],
       comprehensiveTimes: [Double])
```
to generate model inputs (this will be `nil` if and only if `primaryTimes` and  `transferTimes` are different lengths) then create a model object via `StrokeModel(inputs)` and run it using either `StrokeModel.run` or `StrokeModel.runWithVariance`. The results class exposes a `string` property that summarizes results, along with various constants for more details.

### Linux support ###
The package was developed and tested on macOS, but should also run on Linux. In testing (on the [Windows Subsystem for Linux](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)), multithreading via [Grand Central Dispatch](https://github.com/apple/swift-corelibs-libdispatch) worked only intermittently, so `runWithVariance` includes a `useGCD` argument that can revert all computations to a more stable but slower single-threaded mode which is safer on Linux. Tests on Linux do not use GCD.
