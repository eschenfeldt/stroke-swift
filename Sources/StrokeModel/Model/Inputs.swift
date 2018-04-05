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
    let primaries: [StrokeCenter]       // guaranteed to have .centerType == .primary
    let comprehensives: [StrokeCenter]  // guaranteed to have .centerType == .comprehensive

    var minPrimary: StrokeCenter {
        return primaries.min { lhs, rhs in lhs.time! < rhs.time! }! // There has to be at least one primary
    }

    var minComprehensive: StrokeCenter {
        return comprehensives.min { lhs, rhs in lhs.time! < rhs.time! }! // There has to be at least one comprehensive
    }

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

    public var strategies: [Strategy] {
        // Drip and ship strategies will be considered for all primaries that have a designated destination
        //  Any without a destination will be dropped silently
        let dripStrats: [Strategy] = primaries.compactMap { prim in
            Strategy(kind: .dripAndShip, center: prim)
        }
        let primStrat = Strategy(kind: .primary, center: minPrimary)!
        let compStrat = Strategy(kind: .comprehensive, center: minComprehensive)!
        return [primStrat, compStrat] + dripStrats
    }

    public init?(sex: Sex, age: Int, race: Double, timeSinceSymptoms: Double, primaries: [StrokeCenter],
                 comprehensives: [StrokeCenter]) {
        // Confirm all of the stroke centers are of the correct type
        if primaries.contains(where: { $0.centerType != .primary }) { return nil }
        if comprehensives.contains(where: { $0.centerType != .comprehensive }) { return nil }

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
                  comprehensives: comprehensives)!
    }
}
