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
    let allPrimaries: [StrokeCenter]       // guaranteed to have .centerType == .primary
    let allComprehensives: [StrokeCenter]  // guaranteed to have .centerType == .comprehensive
    let usesHospitalPerformance: Bool = false

    var primaries: [StrokeCenter] {
        return allPrimaries.filter({ $0.time != nil })
    }
    var comprehensives: [StrokeCenter] {
        return allComprehensives.filter({ $0.time != nil })
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

    public init?(sex: Sex, age: Int, race: Double, timeSinceSymptoms: Double, primaries: [StrokeCenter],
                 comprehensives: [StrokeCenter]) {
        // Confirm all of the stroke centers are of the correct type
        if primaries.contains(where: { $0.centerType != .primary }) { return nil }
        if comprehensives.contains(where: { $0.centerType != .comprehensive }) { return nil }

        self.sex = sex
        self.age = age
        self.race = race
        self.timeSinceSymptoms = timeSinceSymptoms
        self.allPrimaries = primaries
        self.allComprehensives = comprehensives
    }

    public init?(sex: Sex, age: Int, race: Double, timeSinceSymptoms: Double, primaryTimes: [Double],
                 transferTimes: [Double], comprehensiveTimes: [Double]) {
        guard primaryTimes.count == transferTimes.count else { return nil }
        let times = Array(zip(primaryTimes, transferTimes))

        self.init(sex: sex, age: age, race: race, timeSinceSymptoms: timeSinceSymptoms, primaryTimesAndTransfers: times,
                  comprehensiveTimes: comprehensiveTimes)
    }

    public init(sex: Sex, age: Int, race: Double, timeSinceSymptoms: Double,
                primaryTimesAndTransfers: [(Double, Double)], comprehensiveTimes: [Double]) {

        var comprehensives: [StrokeCenter] = []
        var destination: StrokeCenter? = nil
        var shortestTime = Double.infinity
        for (index, time) in comprehensiveTimes.enumerated() {
            let comp = StrokeCenter(comprehensiveFromTime: time, index: index)
            comprehensives.append(comp)
            if time < shortestTime {
                shortestTime = time
                destination = comp
            }
        }
        var primaries: [StrokeCenter] = []
        for (index, (time, transferTime)) in primaryTimesAndTransfers.enumerated() {
            primaries.append(StrokeCenter(primaryFromTime: time, transferTime: transferTime, index: index,
                                          destination: destination))
        }

        self.init(sex: sex, age: age, race: race, timeSinceSymptoms: timeSinceSymptoms, primaries: primaries,
                  comprehensives: comprehensives)!
    }

    public func setTimes(_ times: [Int: Double]) {
        for center in self.allPrimaries + self.allComprehensives {
            guard let centerID = center.centerID else { continue }
            center.time = times[centerID]
        }
    }
}
