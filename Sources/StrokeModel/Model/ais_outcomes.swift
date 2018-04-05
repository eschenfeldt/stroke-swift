//
//  ais_outcomes.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/2/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

import Foundation

func pLVOgivenAIS(race: Double, addUncertainty: Bool) -> Double {
    func p_lvo_logistic_helper(beta0: Double, beta1: Double, race: Double) -> Double {
        return 1.0 / (1.0 + exp(-beta0 - beta1 * race))
    }
    var pLVO: Double
    if addUncertainty {
        let lower = p_lvo_logistic_helper(beta0: -3.6526, beta1: 0.4141, race: race)
        let upper = p_lvo_logistic_helper(beta0: -2.2067, beta1: 0.6925, race: race)
        pLVO = Double.random() * (upper - lower) + lower
    } else {
        pLVO = p_lvo_logistic_helper(beta0: -2.9297, beta1: 0.5533, race: race)
    }
    return pLVO
}

func pGoodOutcomePostEVTsuccess(timeOnsetReperfusion: Double,
                                nihss: Double) -> Double {
    let beta = (-0.00879544 - 9.01419716e-05 * timeOnsetReperfusion)
    return exp(beta * nihss)
}

func pGoodOutcomeNoReperfusion(nihss: Double) -> Double {
    if nihss >= 20 {
        return 0.05
    } else {
        return (-0.0464 * nihss) + 1.0071
    }
}

func pGoodOutcomeAISnoLVOgotTPA(timeOnsetTPA: Double,
                                nihss: Double) -> Double {
    let baselineProb = 0.001 * pow(nihss, 2) - 0.0615 * nihss + 1
    if timeOnsetTPA > time_limit_tpa() {
        return baselineProb
    } else {
        let oddsRatio = -0.0031 * timeOnsetTPA + 2.068
        let baselineProbToOdds = baselineProb / (1 - baselineProb)
        let newOdds = baselineProbToOdds * oddsRatio
        let adjustedProb = newOdds / (1 + newOdds)
        return adjustedProb
    }
}

func pReperfusionEndovascular() -> Double {
    return 0.71
}

func pEarlyReperfusionThrombolysis(timeToGroin: Double) -> Double {
    return 0.18 * min(70, timeToGroin) / 70
}

struct IschemicModel {

    // Stored Properties
    let sex: Sex
    let age: Int
    let race: Double
    let timeSinceSymptoms: Double
    let primaries: [StrokeCenter]
    let comprehensives: [StrokeCenter]
    let times: IntraHospitalTimes
    let pLVO: Double

    // Computed Properties
    var nihss: Double {
        return Race.toNIHSS(race: race)
    }

    var minPrimary: StrokeCenter {
        return primaries.min { lhs, rhs in lhs.time! < rhs.time! }! // There has to be at least one primary
    }

    var minComprehensive: StrokeCenter {
        return comprehensives.min { lhs, rhs in lhs.time! < rhs.time! }! // There has to be at least one comprehensive
    }

    var minOnsetNeedlePrimary: Double {
        return (timeSinceSymptoms + minPrimary.time! +
                times.doorToNeedlePrimary)
    }

    var minOnsetEVTnoship: Double {
        return (timeSinceSymptoms + minComprehensive.time! +
                times.doorToIntraArterial)
    }

    var modelIsNecessary: Bool {
        return (minOnsetNeedlePrimary <= time_limit_tpa() ||
                minOnsetEVTnoship <= time_limit_evt())
    }
    var cutoffLocation: Strategy? {
        if modelIsNecessary {
            return nil
        } else {
            return no_tx_where_to_go(race: race)
        }
    }

    // Methods
    init(_ inputs: Inputs,
         addTimeUncertainty: Bool = false,
         addLVOuncertainty: Bool = false) {
        sex = inputs.sex
        age = inputs.age
        race = inputs.race
        timeSinceSymptoms = inputs.timeSinceSymptoms
        primaries = inputs.primaries
        comprehensives = inputs.comprehensives
        times = IntraHospitalTimes(withUncertainty: addTimeUncertainty)
        pLVO = pLVOgivenAIS(race: race, addUncertainty: addLVOuncertainty)
    }

    func no_tx_where_to_go(race: Double) -> Strategy {
        if race >= 5.0 {
            return Strategy(kind: .comprehensive, center: minComprehensive)!
        } else {
            return Strategy(kind: .primary, center: minPrimary)!
        }
    }

    func onsetNeedlePrimary(usingHospital primary: StrokeCenter) -> Double {
        return (timeSinceSymptoms + primary.time! +
                times.doorToNeedlePrimary)
    }
    func onset_needle_comprehensive(usingHospital comprehensive: StrokeCenter) -> Double {
        return (timeSinceSymptoms + comprehensive.time! +
                times.doorToNeedleComprehensive)
    }
    func onset_evt_noship(usingHospital comprehensive: StrokeCenter) -> Double {
        return (timeSinceSymptoms + comprehensive.time! +
                times.doorToIntraArterial)
    }
    func onset_evt_ship(usingHospital primary: StrokeCenter) -> Double {
        return (timeSinceSymptoms + primary.time! +
                times.doorToNeedlePrimary + primary.transferTime! +
                times.transferToIntraArterial)
    }

    func getAISoutcomes(key: Strategy) -> Outcome? {
        switch key.kind {
        case .primary:
            return runPrimaryCenter(usingHospital: key.center)
        case .comprehensive:
            return runComprehensiveCenter(usingHospital: key.center)
        case .dripAndShip:
            return runPrimaryThenShip(usingHospital: key.center)
        }
    }

    func runPrimaryCenter(usingHospital primary: StrokeCenter) -> Outcome {
        let pGood = getpGood(onsetToTPA: onsetNeedlePrimary(usingHospital: primary),
                             onsetToEVT: nil)
        let pTPA = 1.0
        let pEVT = 0.0
        let pTransfer = 0.0

        return Outcome(pGood: pGood, pTPA: pTPA,
                       pEVT: pEVT, pTransfer: pTransfer)
    }

    func runComprehensiveCenter(usingHospital comprehensive: StrokeCenter) -> Outcome {

        let pTransfer = 0.0
        var pTPA = 0.0
        let pEVT = pLVO
        if onset_needle_comprehensive(usingHospital: comprehensive) < time_limit_tpa() {
            pTPA = 1.0
        }
        let pGood = getpGood(onsetToTPA: onset_needle_comprehensive(usingHospital: comprehensive),
                                onsetToEVT: onset_evt_noship(usingHospital: comprehensive))

        return Outcome(pGood: pGood, pTPA: pTPA,
                       pEVT: pEVT, pTransfer: pTransfer)
    }

    func runPrimaryThenShip(usingHospital primary: StrokeCenter) -> Outcome? {

        if onset_evt_ship(usingHospital: primary) > time_limit_evt() {
            return nil
        } else {
            let pTPA = 1.0
            let pEVT = pLVO
            let pTransfer = 1.0
            let pGood = getpGood(onsetToTPA: onsetNeedlePrimary(usingHospital: primary),
                                    onsetToEVT: onset_evt_ship(usingHospital: primary))

            return Outcome(pGood: pGood, pTPA: pTPA,
                           pEVT: pEVT, pTransfer: pTransfer)
        }
    }

    func getpGood(onsetToTPA: Double, onsetToEVT: Double?) -> Double {

        var pGood = 0.0

        let baselinepGood = pGoodOutcomeAISnoLVOgotTPA(timeOnsetTPA: onsetToTPA, nihss: nihss)

        pGood += ((1 - pLVO) * baselinepGood)

        var pReperfused = 0.0
        var pNotReperfused = pLVO

        if onsetToEVT != nil {
            pReperfused = pLVO * pReperfusionEndovascular()
            pNotReperfused -= pReperfused
        }

        pGood += pNotReperfused * baselinepGood

        if let onsetToEVTtime = onsetToEVT {
            let pGoodPostEVT = pGoodOutcomePostEVTsuccess(timeOnsetReperfusion: onsetToEVTtime, nihss: nihss)
            var higherpGood = pGoodPostEVT
            if higherpGood < baselinepGood {
                higherpGood = baselinepGood
            }
            pGood += pReperfused * higherpGood
        }
        return pGood
    }
}

struct Outcome {
    let pGood: Double
    let pTPA: Double
    let pEVT: Double
    let pTransfer: Double
}
