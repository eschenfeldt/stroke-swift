//
//  Inputs.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/2/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

import Dispatch

public struct Inputs {
    let sex: Sex
    let age: Int
    let race: Double
    let timeSinceSymptoms: Double
    let primaries: [StrokeCenter]
    let comprehensives: [StrokeCenter]

    public var string: String {
        return """
        Inputs:
        sex: \(sex.string)
        age: \(age)
        RACE: \(race)
        Time from symptoms: \(timeSinceSymptoms)
        # of primaries: \(primaries.count)
        # of comprehensives: \(comprehensives.count)
        """
    }

    public init(sex: Sex, age: Int, race: Double, timeSinceSymptoms: Double, primaries: [StrokeCenter],
                comprehensives: [StrokeCenter]) {
        self.sex = sex
        self.age = age
        self.race = race
        self.timeSinceSymptoms = timeSinceSymptoms
        self.primaries = primaries
        self.comprehensives = comprehensives
    }

    public init?(sex: Sex, age: Int, race: Double, timeSinceSymptoms: Double, primaryTimes: [Double],
                 transferTimes: [Double], comprehensiveTimes: [Double]) {
        guard primaryTimes.count == transferTimes.count else { return nil }

        let times = zip(primaryTimes, transferTimes)
        var primaries: [StrokeCenter] = []
        for (index, (time, transferTime)) in times.enumerated() {
            primaries.append(StrokeCenter(primaryFromTime: time, transferTime: transferTime, index: index))
        }

        var comprehensives: [StrokeCenter] = []
        for (index, time) in comprehensiveTimes.enumerated() {
            comprehensives.append(StrokeCenter(comprehensiveFromTime: time, index: index))
        }
        self.init(sex: sex, age: age, race: race, timeSinceSymptoms: timeSinceSymptoms, primaries: primaries,
                  comprehensives: comprehensives)
    }

    public init(sex: Sex, age: Int, race: Double, timeSinceSymptoms: Double,
                primaryTimesAndTransfers: [(Double, Double)], comprehensiveTimes: [Double]) {
        var primaries: [StrokeCenter] = []
        for (index, (time, transferTime)) in primaryTimesAndTransfers.enumerated() {
            primaries.append(StrokeCenter(primaryFromTime: time, transferTime: transferTime, index: index))
        }

        var comprehensives: [StrokeCenter] = []
        for (index, time) in comprehensiveTimes.enumerated() {
            comprehensives.append(StrokeCenter(comprehensiveFromTime: time, index: index))
        }
        self.init(sex: sex, age: age, race: race, timeSinceSymptoms: timeSinceSymptoms, primaries: primaries,
                  comprehensives: comprehensives)
    }
}
