//
//  ResultsTests.swift
//  StrokeModelTests
//
//  Created by Patrick Eschenfeldt (ITA) on 4/4/18.
//

import XCTest
@testable import StrokeModel

class ResultsTests: XCTestCase {

    var primary1 = StrokeCenter(primaryFromFullName: "Primary 1")
    var primary2 = StrokeCenter(primaryFromFullName: "Primary 2")
    var comprehensive = StrokeCenter(comprehensiveFromFullName: "Comprehensive")

    override func setUp() {
        super.setUp()
        primary1.addTransferDestination(comprehensive, transferTime: 0)
        primary2.addTransferDestination(comprehensive, transferTime: 0)
    }

    var strategies: [Strategy] {
        return [Strategy(kind: .primary, center: primary1)!,
                Strategy(kind: .dripAndShip, center: primary1)!,
                Strategy(kind: .dripAndShip, center: primary2)!,
                Strategy(kind: .comprehensive, center: comprehensive)!]
    }
    var centers: [StrokeCenter] {
        return [primary1, primary2, comprehensive]
    }
    var totalCount: Int {
        return strategies.reduce(0) { sum, strat in sum + optimalCount(strategy: strat) }
    }

    func optimalCount(strategy: Strategy) -> Int {
        let center = strategy.center
        switch strategy.kind {
        case .primary:
            if center == primary1 {
                return 100
            } else { return 0 }
        case .comprehensive:
            if center == comprehensive {
                return 400
            } else { return 0 }
        case .dripAndShip:
            if center == primary1 {
                return 300
            } else if center == primary2 {
                return 500
            } else { return 0 }
        }
    }
    func optimalCount(center: StrokeCenter) -> Int {
        switch center.centerType {
        case .primary:
            let primStrat = Strategy(kind: .primary, center: center)!
            let dripStrat = Strategy(kind: .dripAndShip, center: center)!
            return optimalCount(strategy: primStrat) + optimalCount(strategy: dripStrat)
        case .comprehensive:
            return optimalCount(strategy: Strategy(kind: .comprehensive, center: center)!)
        }
    }
    func optimalPercentage(strategy: Strategy) -> Double {
        return Double(optimalCount(strategy: strategy)) / Double(totalCount)
    }
    func optimalPercentage(center: StrokeCenter) -> Double {
        return Double(optimalCount(center: center)) / Double(totalCount)
    }

    func testCountByCenter() {

        func appendResults( toArray array: inout [SingleRunResults], forStrategy strategy: Strategy) {
            for _ in 1...optimalCount(strategy: strategy) {
                array.append(SingleRunResults(optimalStrategy: strategy, maxBenefit: strategy, costs: [:], qalys: [:]))
            }
        }

        var resultsArray: [SingleRunResults] = []
        for strategy in strategies { appendResults(toArray: &resultsArray, forStrategy: strategy) }

        let results = MultiRunResults(fromResults: resultsArray)

        guard let countsByCenter = results.countsByCenter else {
            XCTFail("Counts by center should not be nil")
            return
        }
        for center in centers {
            XCTAssertEqual(countsByCenter[center], optimalCount(center: center))
        }
        for center in centers {
            XCTAssertEqual(results.percentagesByCenter[center], optimalPercentage(center: center))
        }
    }

    func testPercentageByCenter() {
        let percentages: [Strategy: Double] = strategies.reduce([:]) { dict, strat in
            var dict = dict
            let newPerc = optimalPercentage(strategy: strat)
            if let curPerc = dict[strat] {
                dict[strat] = curPerc + newPerc
            } else {
                dict[strat] = newPerc
            }
            return dict
        }
        guard let results = MultiRunResults(fromPercentages: percentages) else {
            XCTFail("Failed to make results")
            return
        }
        for center in centers {
            XCTAssertEqual(results.percentagesByCenter[center], optimalPercentage(center: center))
        }
    }

    static var allTests = [
        ("testCountByCenter", testCountByCenter),
        ("testPercentageByCenter", testPercentageByCenter)
    ]
}
