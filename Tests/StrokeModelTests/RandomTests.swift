//
//  RandomTests.swift
//  StrokeModelTests
//
//  Created by Patrick Eschenfeldt (ITA) on 4/2/18.
//

import XCTest
@testable import StrokeModel

class RandomTests: XCTestCase {

    func testRandomInt() {
        var minInt = Int.max
        var maxInt = Int.min
        let end = 10
        for _ in 0...10000 {
            let randInt = Int.random(below: end)
            if randInt > 10 || randInt < 0 {
                XCTFail("Incorrect random number \(randInt)")
            }
            if randInt < minInt { minInt = randInt }
            if randInt > maxInt { maxInt = randInt }
        }
        XCTAssertEqual(minInt, 0)
        XCTAssertEqual(maxInt, end - 1)
    }

    func testRandomDouble() {
        var minDouble = -1.0
        var maxDouble = 2.0
        for _ in 0...10_000 {
            let randDouble = Double.random()
            if randDouble < 0 || randDouble > 1 {
                XCTFail("Incorrect random number \(randDouble)")
            }
            if randDouble < minDouble { minDouble = randDouble }
            if randDouble > maxDouble { maxDouble = randDouble }
        }
        XCTAssertGreaterThan(maxDouble, 1.0 - 1e-2)
        XCTAssertLessThan(minDouble, 1e-2)
    }

    static var allTests = [
        ("testRandomInt", testRandomInt),
        ("testRandomDouble", testRandomDouble),
    ]

}
