//
//  constants.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/2/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

//import Foundation

public enum Sex: Int {
    case male = 0
    case female = 1

    public var string: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }
}

enum States: Int {
    case genPop = 0, mrs0, mrs1, mrs2, mrs3, mrs4, mrs5, mrs6
    static let DEATH = States.mrs6
}

public struct Strategy: Hashable {

    public enum Kind {
        case primary
        case comprehensive
        case dripAndShip
    }

    public let kind: Kind
    public let center: StrokeCenter

    public init?(kind: Kind, center: StrokeCenter) {
        switch kind {
        case .primary:
            if center.centerType != .primary { return nil }
        case .dripAndShip:
            if center.centerType != .primary || center.transferDestination == nil {
                return nil
            }
        case .comprehensive:
            if center.centerType != .comprehensive { return nil }
        }
        self.kind = kind
        self.center = center
    }

    public var string: String {
        switch kind {
        case .primary:
            return "Primary (\(center.shortName))"
        case .dripAndShip:
            return "Drip and Ship (\(center.shortName) to \(center.transferDestination!.shortName))"
        case .comprehensive:
            return "Comprehensive (\(center.shortName))"
        }
    }

}

func p_call_is_mimic() -> Double {
    return (1635.0 + 191.0) / 2402.0
}

func p_call_is_hemorrhagic() -> Double {
    return (16.0 + 85.0) / 2402.0
}

func time_limit_tpa() -> Double {
    return 270
}

func time_limit_evt() -> Double {
    return 360
}

func getDoorToNeedlePrimary(_ withUncertainty: Bool = true) -> Double {
    if withUncertainty {
        let max = 83.00
        let min = 47.00
        return Double.random() * (max - min) + min
    } else {
        return 61.00
    }
}

func getDoorToNeedleComprehensive(_ withUncertainty: Bool = true) -> Double {
    if withUncertainty {
        let max = 70.00
        let min = 39.00
        return Double.random() * (max - min) + min
    } else {
        return 52.00
    }
}

func getDoorToIntraArterialComprehensive(_ withUncertainty: Bool = true) -> Double {
    if withUncertainty {
        let max = 192.00
        let min = 83.00
        return Double.random() * (max - min) + min
    } else {
        return 145.00
    }
}

struct IntraHospitalTimes {
    let doorToNeedle: [StrokeCenter: Double]
    let doorToIntraArterial: [StrokeCenter: Double]

    init(primaries: [StrokeCenter], comprehensives: [StrokeCenter], withUncertainty: Bool = false,
         dtnPerf: Double? = nil, dtpPerf: Double? = nil) {
        var dtn: [StrokeCenter: Double] = [:]
        var dtia: [StrokeCenter: Double] = [:]
        for prim in primaries {
            dtn[prim] = prim.getDoorToNeedle(withUncertainty: withUncertainty, performanceLevel: dtnPerf)
            if let trans = prim.transferDestination {
                dtn[trans] = trans.getDoorToNeedle(withUncertainty: withUncertainty, performanceLevel: dtnPerf)
                dtia[trans] = trans.getDoorToPuncture(withUncertainty: withUncertainty, performanceLevel: dtpPerf)
            }
        }
        for comp in comprehensives {
            dtn[comp] = comp.getDoorToNeedle(withUncertainty: withUncertainty, performanceLevel: dtnPerf)
            dtia[comp] = comp.getDoorToPuncture(withUncertainty: withUncertainty, performanceLevel: dtpPerf)
        }
        doorToNeedle = dtn
        doorToIntraArterial = dtia
    }
}

func breakUpAISpatients(pGoodOutcome: Double,
                        nihss: Double) -> [States: Double] {
    let genpop = 0.0
    var mrs6: Double
    if nihss < 7 {
        mrs6 = 0.042
    } else if nihss < 13 {
        mrs6 = 0.139
    } else if nihss < 21 {
        mrs6 = 0.316
    } else {
        mrs6 = 0.535
    }

    // Good outcomes
    let mrs0 = 0.205627706 * pGoodOutcome
    let mrs1 = 0.341991342 * pGoodOutcome
    let mrs2 = pGoodOutcome - mrs1 - mrs0

    // And bad outcomes
    let mrs3 = 0.35678392 * (1 - pGoodOutcome - mrs6)
    let mrs4 = 0.432160804 * (1 - pGoodOutcome - mrs6)
    let mrs5 = 0.211055276 * (1 - pGoodOutcome - mrs6)

    return [
        States.genPop: genpop,
        States.mrs0: mrs0,
        States.mrs1: mrs1,
        States.mrs2: mrs2,
        States.mrs3: mrs3,
        States.mrs4: mrs4,
        States.mrs5: mrs5,
        States.mrs6: mrs6
    ]
}

let hazardsMortality = [
    States.genPop: 1.00,
    States.mrs0: 1.53,
    States.mrs1: 1.52,
    States.mrs2: 2.17,
    States.mrs3: 3.18,
    States.mrs4: 4.55,
    States.mrs5: 6.55
]

func hazardMort(mrs: States) -> Double? {
    return hazardsMortality[mrs]
}

let utilities = [
    States.genPop: 1.00,
    States.mrs0: 1.00,
    States.mrs1: 0.84,
    States.mrs2: 0.78,
    States.mrs3: 0.71,
    States.mrs4: 0.44,
    States.mrs5: 0.18
]

func utilitiesMRS(mrs: States) -> Double? {
    return utilities[mrs]
}

final class Costs {

    static let shared = Costs()

    var year: Int?
    var days90Ischemic: [States: Double] = [
        States.genPop: 0,
        States.mrs0: 6302,
        States.mrs1: 9448,
        States.mrs2: 14918,
        States.mrs3: 26218,
        States.mrs4: 32502,
        States.mrs5: 26071,
    ]
    var days90ICH: [States: Double] = [
        States.genPop: 0,
        States.mrs0: 9500,
        States.mrs1: 15500,
        States.mrs2: 18700,
        States.mrs3: 27400,
        States.mrs4: 27300,
        States.mrs5: 27300,
    ]
    var annual: [States: Double] = [
        States.genPop: 0,
        States.mrs0: 2921,
        States.mrs1: 3905,
        States.mrs2: 6501,
        States.mrs3: 16922,
        States.mrs4: 42335,
        States.mrs5: 39723,
    ]
    var death: Double = 8100
    var ivt: Double = 13419
    var evt: Double = 6400
    var transfer: Double = 763

    private init() { }

    private struct BaseYears {
        var ischemic = 2014
        var ich = 2008
        var annual = 2014
        var death = 2008
        var ivt = 2014
        var evt = 2014
        var transfer = 2010

        init(year: Int?) {
            guard let year = year else { return }
            ischemic = year
            ich = year
            annual = year
            death = year
            ivt = year
            evt = year
            transfer = year
        }
    }

    func inflate(targetYear: Int) {
        guard targetYear != year else { return }

        let baseYears = BaseYears(year: year)

        for (state, cost) in days90Ischemic {
            days90Ischemic[state] = Conversion.run(originalYear: baseYears.ischemic,
                                                     updatedYear: targetYear, cost: cost)
        }
        for (state, cost) in days90ICH {
            days90ICH[state] = Conversion.run(originalYear: baseYears.ich, updatedYear: targetYear, cost: cost)
        }
        for (state, cost) in annual {
            annual[state] = Conversion.run(originalYear: baseYears.annual, updatedYear: targetYear, cost: cost)
        }
        death = Conversion.run(originalYear: baseYears.death, updatedYear: targetYear, cost: death)
        ivt = Conversion.run(originalYear: baseYears.ivt, updatedYear: targetYear, cost: ivt)
        evt = Conversion.run(originalYear: baseYears.evt, updatedYear: targetYear, cost: evt)
        transfer = Conversion.run(originalYear: baseYears.transfer, updatedYear: targetYear, cost: transfer)

        year = targetYear
    }
}

func cost_ivt() -> Double {
    return Costs.shared.ivt
}

func cost_evt() -> Double {
    return Costs.shared.evt
}

func cost_transfer() -> Double {
    return Costs.shared.transfer
}

func first_year_costs(statesHemorrhagic: [States: Double],
                      statesIschemic: [States: Double]) -> Double {
    let mult90: Double = 90 / 360
    let multRest: Double = 1 - mult90
    var cost = 0.0
    for i in 0..<States.mrs6.rawValue {
        let state = States(rawValue: i)!
        cost += statesHemorrhagic[state]! * (
            mult90 * Costs.shared.days90ICH[state]! +
            multRest * Costs.shared.annual[state]!
        )
        cost += statesIschemic[state]! * (
            mult90 * Costs.shared.days90Ischemic[state]! +
            multRest * Costs.shared.annual[state]!
        )
    }
    cost += statesHemorrhagic[States.DEATH]! * Costs.shared.death
    cost += statesIschemic[States.DEATH]! * Costs.shared.death
    return cost
}

func annual_cost(states: [States: Double]) -> Double {
    var cost = 0.0
    for i in 0..<States.mrs6.rawValue {
        let state = States(rawValue: i)!
        cost += states[state]! * Costs.shared.annual[state]!
    }
    cost += states[States.DEATH]! * Costs.shared.death
    return cost
}
