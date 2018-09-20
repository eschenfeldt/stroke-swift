//
//  create_random_sets.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/3/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

extension Inputs {

    public static func createRandomSet() -> Inputs {
        let sex = Sex(rawValue: Int.random(in: 0...1))!
        let age = Int.random(in: 30...85)
        let race = Double(Int.random(in: 0...9))
        let timeSinceSymptom = Double.random(in: 10...100)
        let numPrimaries = Int.random(in: 1...6)
        var primaries: [StrokeCenter] = []
        var minTimeToPrimary = Double.infinity
        for id in 0...numPrimaries {
            let timeToPrimary = Double.random(in: 10...150)
            if timeToPrimary < minTimeToPrimary { minTimeToPrimary = timeToPrimary }
            let transferTime = Double.random(in: 0...200)
            let primary = StrokeCenter(primaryFromFullName: "Primary \(id)")
            primary.time = timeToPrimary
            let destination = StrokeCenter(comprehensiveFromFullName: "Drip and ship target \(id)")
            primary.addTransferDestination(destination, transferTime: transferTime)
            primaries.append(primary)
        }

        let timeToComprehensive = Double.random(in: minTimeToPrimary...350)
        let comprehensive = StrokeCenter(comprehensiveFromFullName: "Comprehensive")
        comprehensive.time = timeToComprehensive

        return Inputs(sex: sex, age: age, race: race, timeSinceSymptoms: timeSinceSymptom,
                      primaries: primaries, comprehensives: [comprehensive])!
    }

    public static func createNontrivialRandomSet() -> Inputs {
        var out = createRandomSet()
        var model = IschemicModel(out)
        while !model.modelIsNecessary {
            out = createRandomSet()
            model = IschemicModel(out)
        }
        return out
    }

    public static func createRandomSets(_ numberOfSets: Int,
                                        nontrivialOnly: Bool = false) -> [Inputs] {

        var parameterSets = [Inputs]()

        for _ in 0..<numberOfSets {
            var newSet: Inputs
            if nontrivialOnly {
                newSet = createNontrivialRandomSet()
            } else {
                newSet = createRandomSet()
            }
            parameterSets.append(newSet)
        }

        return parameterSets
    }
}
