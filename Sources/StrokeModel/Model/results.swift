//
//  results.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 11/3/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

public protocol Results {
    var string: String { get }
    var bestStrategy: String { get }
}

public struct SingleRunResults: Equatable, Results {

    public internal(set) var optimalLocation: Strategy?
    public internal(set) var maxBenefit: Strategy?
    public let costs: [Strategy: Double]
    public let qalys: [Strategy: Double]

    public var string: String {
        var out = ""
        for strategy in costs.keys {
            out += """
            \(strategy.string):
            cost = \(costs[strategy]!)
            QALY = \(qalys[strategy]!)\n
            """
        }
        if let optimalStrategy = optimalLocation {
            out += "Optimal: \(optimalStrategy.string)\n"
        } else {
            out += "Optimal not computed.\n"
        }
        if let maxBenefit = maxBenefit {
            out += "Max Benefit: \(maxBenefit.string)"
        }
        return out
    }

    public var bestStrategy: String {
        if let optimalStrategy = optimalLocation {
            return optimalStrategy.string
        } else {
            return "Not computed"
        }
    }

    public static func == (lhs: SingleRunResults, rhs: SingleRunResults) -> Bool {
        let sameOptimal = lhs.optimalLocation == rhs.optimalLocation
        let sameMaxBenefit = lhs.maxBenefit == rhs.maxBenefit

        let sameKeys = lhs.costs.keys == rhs.costs.keys
        var sameDicts = sameKeys
        if sameKeys {
            for key in lhs.costs.keys {
                if abs(lhs.costs[key]! - rhs.costs[key]!) > 1e-2 {
                    sameDicts = false
                    break
                }
                if abs(lhs.qalys[key]! - rhs.qalys[key]!) > 1e-3 {
                    sameDicts = false
                    break
                }
            }
        }

        return sameOptimal && sameMaxBenefit && sameDicts
    }

}

public struct MultiRunResults: Results, Equatable, CustomDebugStringConvertible {

    public let optimalLocation: Strategy
    public let maxBenefit: Strategy?
    public let counts: [Strategy: Int]?
    public let percentages: [Strategy: Double]
    public let maxBenefitCounts: [Strategy: Int]?
    public let maxBenefitPercentages: [Strategy: Double]
    public let results: [SingleRunResults]

    public var bestStrategy: String {
        return optimalLocation.string
    }

    public var countsByCenter: [StrokeCenter: Int]? {
        guard let counts = counts else { return nil }
        var countsByCenter: [StrokeCenter: Int] = [:]
        for (strategy, count) in counts {
            switch strategy {
            case let .comprehensive(center), let .dripAndShip(center), let .primary(center):
                if let cumulativeCount = countsByCenter[center] {
                    countsByCenter[center] = cumulativeCount + count
                } else {
                    countsByCenter[center] = count
                }
            }
        }
        return countsByCenter
    }
    public var percentagesByCenter: [StrokeCenter: Double] {
        // If we have counts, do the summing on those rather than on percentages
        if let countsByCenter = countsByCenter {
            let total = countsByCenter.reduce(0) { sum, pair in
                return sum + pair.value
            }
            return countsByCenter.mapValues { count in Double(count) / Double(total) }
        }
        var percentagesByCenter: [StrokeCenter: Double] = [:]
        for (strategy, percentage) in percentages {
            switch strategy {
            case let .comprehensive(center), let .dripAndShip(center), let .primary(center):
                if let cumulativePercentage = percentagesByCenter[center] {
                    percentagesByCenter[center] = cumulativePercentage + percentage
                } else {
                    percentagesByCenter[center] = percentage
                }
            }
        }
        return percentagesByCenter
    }

    public var string: String {
        var out = "Optimal: \(bestStrategy)\n"
        if let maxBenefit = maxBenefit {
            out += "Max Benefit: \(maxBenefit.string)\n"
        }
        out += "Based on \(results.count) iterations\n"
        out += "Optimal Percentages:\n"
        for (strategy, optimalPercentage) in percentages {
            out += "\(strategy.string): \(optimalPercentage * 100)%\n"
        }
        out += "Max Benefit Percentages:\n"
        for (strategy, maxBenefitPercentage) in maxBenefitPercentages {
            out += "\(strategy.string): \(maxBenefitPercentage * 100)%\n"
        }
        return out
    }

    public var debugDescription: String {
        return string
    }

    init(fromResults results: [SingleRunResults]) {
        self.results = results
        let n = Double(results.count)

        var tempOptimalCounts = [Strategy: Int]()
        var tempMaxBenefitCounts = [Strategy: Int]()
        for thisResult in results {
            if let optimal = thisResult.optimalLocation {
                if let curOptCount = tempOptimalCounts[optimal] {
                    tempOptimalCounts[optimal] = curOptCount + 1
                } else {
                    tempOptimalCounts[optimal] = 1
                }
            } else {
                print("no optimal location for \(thisResult)")
            }
            if let maxBenefit = thisResult.maxBenefit {
                if let curBenCount = tempMaxBenefitCounts[maxBenefit] {
                    tempMaxBenefitCounts[maxBenefit] = curBenCount + 1
                } else {
                    tempMaxBenefitCounts[maxBenefit] = 1
                }
            }
        }
        self.counts = tempOptimalCounts
        self.maxBenefitCounts = tempMaxBenefitCounts

        var percentagesTemp = [Strategy: Double]()
        var maxOptimalCount = 0
        var optimalTemp: Strategy? = nil
        for (strat, count) in tempOptimalCounts {
            percentagesTemp[strat] = Double(count) / n
            if count > maxOptimalCount {
                optimalTemp = strat
                maxOptimalCount = count
            }
        }
        self.percentages = percentagesTemp
        optimalLocation = optimalTemp!

        var benefitTemp = [Strategy: Double]()
        var maxBenefitCount = 0
        var maxBenefitTemp: Strategy? = nil
        for (strat, count) in tempMaxBenefitCounts {
            benefitTemp[strat] = Double(count) / n
            if count > maxBenefitCount {
                maxBenefitTemp = strat
                maxBenefitCount = count
            }
        }
        self.maxBenefitPercentages = benefitTemp
        maxBenefit = maxBenefitTemp
    }

    init?(fromPercentages percentages: [Strategy: Double]) {
        self.percentages = percentages
        let sortedPercentages = percentages.sorted { lhs, rhs in lhs.value < rhs.value }
        guard let optimal = sortedPercentages.last else { return nil }
        optimalLocation = optimal.key
        maxBenefit = nil
        maxBenefitPercentages = [:]
        results = []
        counts = nil
        maxBenefitCounts = nil
    }

    public static func == (lhs: MultiRunResults, rhs: MultiRunResults) -> Bool {
        // Equality based only on optimality percentages for now.

        let margin = 1e-2

        let strategies = lhs.percentages.keys
        for strategy in strategies {
            switch (lhs.percentages[strategy], rhs.percentages[strategy]) {
            case (let lhsPercentage?, let rhsPercentage?):
                if abs(lhsPercentage - rhsPercentage) > margin {
                    return false
                }
            case (let lhsPercentage?, nil):
                if lhsPercentage > margin {
                    return false
                }
            case (nil, let rhsPercentage?):
                if rhsPercentage > margin {
                    return false
                }
            case (nil, nil):
                break
            }
        }
        return true
    }
}
