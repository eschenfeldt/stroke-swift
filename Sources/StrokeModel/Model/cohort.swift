//
//  cohort.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/2/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

import Foundation

public final class Population {

    public static let endAge = 100
    let startAge: Int
    let sex: Sex
    let nihss: Double
    let aisOutcome: Outcome?
    let simtype: Strategy
    var costsPerYear: [Double] = []
    var statesInMarkov: [States: Double] = [:]
    var states: [[States: Double]] = []
    var qalysPerYear: [Double] = []
    var qalys: Double?
    var costs: Double?

    init(aisModel: IschemicModel, aisOutcome: Outcome, simtype: Strategy) {
        startAge = aisModel.age
        sex = aisModel.sex
        nihss = aisModel.nihss
        self.aisOutcome = aisOutcome
        self.simtype = simtype
    }

    func analyze() {
        break_into_states()
        run_markov()
        get_qalys_per_year()
        get_costs_per_year()
        qalys = simpsonsOne3rdCorrection(yearlyValue: qalysPerYear,
                                          yearsHorizon: nil)
        costs = simpsonsOne3rdCorrection(yearlyValue: costsPerYear,
                                          yearsHorizon: nil)
    }

    func break_into_states() {
        let callPopulation = 1.0
        let popMimic = callPopulation * p_call_is_mimic()
        let popHemorrhagic = callPopulation * p_call_is_hemorrhagic()
        let popIschemic = callPopulation - popMimic - popHemorrhagic

        let mrsOfAIS = breakUpAISpatients(
            pGoodOutcome: aisOutcome!.pGood, nihss: nihss)

        var states = [States: Double]()
        var statesIschemic = [States: Double]()
        var statesHemorrhagic = [States: Double]()

        for i in 0...States.mrs6.rawValue {
            let state = States(rawValue: i)!

            let fromMimic = state == States.genPop ? popMimic : 0.0
            let fromIschemic = popIschemic * mrsOfAIS[state]!
            let fromHemorrhagic = popHemorrhagic * mrsOfAIS[state]!

            statesIschemic[state] = fromIschemic
            statesHemorrhagic[state] = fromHemorrhagic
            states[state] = fromMimic + fromIschemic + fromHemorrhagic
        }

        var baselineYearOneCosts = first_year_costs(
            statesHemorrhagic: statesHemorrhagic,
            statesIschemic: statesIschemic)
        baselineYearOneCosts += (cost_ivt() * aisOutcome!.pTPA *
                                    popIschemic)
        baselineYearOneCosts += (cost_evt() * aisOutcome!.pEVT *
                                    popIschemic)
        baselineYearOneCosts += (cost_transfer() * aisOutcome!.pTransfer *
                                    popIschemic)

        costsPerYear.append(baselineYearOneCosts)
        statesInMarkov = states
    }

    func run_markov() {
        var currentState = statesInMarkov
        var startOfCycles = [[States: Double]]()
        var currentAge = startAge
        while currentAge < Population.endAge {
            startOfCycles.append(currentState)
            for i in 0...States.mrs5.rawValue {
                let mrs = States(rawValue: i)!
                let pDead = LifeTables.adjustedMortality(
                    sex: sex, age: currentAge,
                    adjustment: hazardMort(mrs: mrs)!)
                let change = currentState[mrs]! * pDead
                currentState[States.mrs6] = (currentState[States.mrs6]! +
                                               change)
                currentState[mrs] = (currentState[mrs]! - change)
            }
            currentAge += 1
        }
        startOfCycles.append(currentState)
        states = startOfCycles
    }

    func get_qalys_per_year() {
        let continuousDiscount = 0.03
        let discreteDiscount = exp(continuousDiscount) - 1
        for (cycle, state) in states.enumerated() {
            var qaly = 0.0
            for i in 0...States.mrs5.rawValue {
                let mrs = States(rawValue: i)!
                qaly += state[mrs]! * utilitiesMRS(mrs: mrs)!
            }
            qaly /= pow(1 + discreteDiscount, Double(cycle))
            qalysPerYear.append(qaly)
        }
    }

    func get_costs_per_year() {
        let continuousDiscount = 0.03
        let discreteDiscount = exp(continuousDiscount) - 1
        for (cycle, state) in states.enumerated() {
            if cycle == 0 {
                continue
            } else {
                var costs = annual_cost(states: state)
                costs /= pow(1 + discreteDiscount, Double(cycle))
                costsPerYear.append(costs)
            }
        }
    }
}

func simpsonsOne3rdCorrection(yearlyValue: [Double],
                              yearsHorizon: Int?) -> Double {
    var multiplier = 1.0 / 3
    var sum = yearlyValue[0] * multiplier
    let startIndex = 1
    let endIndex = yearsHorizon ?? yearlyValue.count - 1

    for i in startIndex...endIndex {
        if i == endIndex {
            multiplier = 1.0 / 3
        } else {
            if i % 2 == 0 {
                multiplier = 2.0 / 3
            } else {
                multiplier = 4.0 / 3
            }
        }
        sum += (yearlyValue[i] * multiplier)
    }
    return sum
}
