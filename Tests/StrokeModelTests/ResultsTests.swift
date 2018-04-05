//
//  ResultsTests.swift
//  StrokeModelTests
//
//  Created by Patrick Eschenfeldt (ITA) on 4/4/18.
//

import XCTest
@testable import StrokeModel

class ResultsTests: XCTestCase {

    let primary1 = StrokeCenter(primaryFromFullName: "Primary 1")
    let primary2 = StrokeCenter(primaryFromFullName: "Primary 2")
    let comprehensive = StrokeCenter(comprehensiveFromFullName: "Comprehensive")
    var strategies: [Strategy] {
        return [.primary(primary1), .dripAndShip(primary1), .dripAndShip(primary2),
                .comprehensive(comprehensive)]
    }
    var centers: [StrokeCenter] {
        return [primary1, primary2, comprehensive]
    }
    var totalCount: Int {
        return strategies.reduce(0) { sum, strat in sum + optimalCount(strategy: strat) }
    }

    func optimalCount(strategy: Strategy) -> Int {
        switch strategy {
        case .primary(let center):
            if center == primary1 {
                return 100
            } else { return 0 }
        case .comprehensive(let center):
            if center == comprehensive {
                return 400
            } else { return 0 }
        case .dripAndShip(let center):
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
            return optimalCount(strategy: .primary(center)) + optimalCount(strategy: .dripAndShip(center))
        case .comprehensive:
            return optimalCount(strategy: .comprehensive(center))
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
                array.append(SingleRunResults(optimalLocation: strategy, maxBenefit: strategy, costs: [:], qalys: [:]))
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
