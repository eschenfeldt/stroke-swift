import XCTest
@testable import StrokeModel

// swiftlint:disable line_length
final class StrokeModelTests: XCTestCase {

    #if os(Linux)
    static let useGCD = false
    #else
    static let useGCD = true
    #endif

    class Resource {
        static var resourcePath = "./Tests/StrokeModelTests"

        let name: String
        let type: String

        init(name: String, type: String) {
            self.name = name
            self.type = type
        }

        var path: String {
            #if os(Linux)
            let filename: String = type.isEmpty ? name : "\(name).\(type)"
            return "\(Resource.resourcePath)/\(filename)"
            #else
            guard let path: String = Bundle(for: Swift.type(of: self)).path(forResource: name, ofType: type) else {
                let filename: String = type.isEmpty ? name : "\(name).\(type)"
                return "\(Resource.resourcePath)/\(filename)"
            }
            return path
            #endif
        }
    }

    func testBaseCase() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let line = "Sex.FEMALE,65,7,45,30,60,45,Comprehensive,105661.80362174989,12.366857351113733,99207.75337383134,12.530716127384592,99390.08215608605,12.527639287639298,Comprehensive,lifetime"
        guard let args = ArgumentsAndResults(singleRunLine: line) else {
            XCTFail("Parsing failure")
            return
        }
        args.test()
    }

    func testBaseCaseWithVariance() {
        let line = "Sex.FEMALE,65,7,45,30,60,45,0,64.71899999994497,35.281000000008476,lifetime"
        guard let args = ArgumentsAndResults(multiRunLine: line) else {
            XCTFail("Parsing failure")
            return
        }
        args.test(varyTime: true, varyLVO: true, simulationCount: 25_000)
    }

    func testBaseCaseWithTimeVariance() {
        let line = "Sex.FEMALE,65,7,45,30,60,45,0,80.70000000000438,19.300000000000217,lifetime"
        guard let args = ArgumentsAndResults(multiRunLine: line) else {
            XCTFail("Parsing failure")
            return
        }
        args.test(varyTime: true, varyLVO: false, simulationCount: 25_000)
    }

    func testBaseCaseWithLVOVariance() {
        let line = "Sex.FEMALE,65,7,45,30,60,45,0,59.6599999999967,40.34000000000054,lifetime"
        guard let args = ArgumentsAndResults(multiRunLine: line) else {
            XCTFail("Parsing failure")
            return
        }
        args.test(varyTime: false, varyLVO: true, simulationCount: 25_000)
    }

    func testMany() {
        let filepath = Resource(name: "random_parameter_sets", type: "csv").path
        var allCases: String = ""
        do {
            allCases = try String(contentsOfFile: filepath, encoding: .utf8)
        } catch {
            XCTFail("Couldn't read random parameter sets")
        }
        let rows = allCases.components(separatedBy: "\n")
        for row in rows {
            guard let args = ArgumentsAndResults(singleRunLine: row) else {
                continue
            }
            args.test()
        }
    }

    func testOneWithVariance() {
        let line = "0,67,1,89.71703842708503,41.213686471108666,46.322809484559244,67.57162583879008,13.283999999998077,78.70300000001174,8.013000000000998,lifetime"
        guard let args = ArgumentsAndResults(multiRunLine: line) else {
            XCTFail("Parsing problem")
            return
        }
        args.test(simulationCount: 100_000)
    }

    func testManyWithVariance() {
        let filepath = Resource(name: "random_parameter_sets_with_variance", type: "csv").path
        var allCases: String = ""
        do {
            allCases = try String(contentsOfFile: filepath, encoding: .utf8)
        } catch {
            XCTFail("Couldn't read random parameter sets")
        }
        let rows = allCases.components(separatedBy: "\n")
        for row in rows.prefix(10) {
            guard let args = ArgumentsAndResults(multiRunLine: row) else {
                continue
            }
            args.test(simulationCount: 25_000)
        }
    }

    func testPerformance() {
        let filepath = Resource(name: "random_parameter_sets_for_performance", type: "csv").path
        var allCases: String = ""
        do {
            allCases = try String(contentsOfFile: filepath, encoding: .utf8)
        } catch {
            XCTFail("Couldn't read random parameter sets")
        }
        let rows = allCases.components(separatedBy: "\n")
        let inputSets = rows.map({ ArgumentsAndResults(singleRunLine: $0) })
            .compactMap({$0?.inputs}).prefix(1000)
        self.measure {
            for inputs in inputSets {
                let model = StrokeModel(inputs)
                _ = model.run(addTimeUncertainty: false, addLVOuncertainty: false)
            }
        }
    }

    func testPerformanceWithVariance() {
        let filepath = Resource(name: "random_parameter_sets_for_performance", type: "csv").path
        var allCases: String = ""
        do {
            allCases = try String(contentsOfFile: filepath, encoding: .utf8)
        } catch {
            XCTFail("Couldn't read random parameter sets")
        }
        let rows = allCases.components(separatedBy: "\n")
        let inputSets = rows.map({ ArgumentsAndResults(singleRunLine: $0) })
            .compactMap({$0?.inputs}).prefix(10)
        self.measure {
            for inputs in inputSets {
                let model = StrokeModel(inputs)
                _ = model.runWithVariance(simulationCount: 1000, useGCD: StrokeModelTests.useGCD)
            }
        }
    }

    func testResultsSumming() {
        let line = "1,65,4,45,30,60,45,0,20.231999999999665,79.7679999999955,lifetime"
        guard let args = ArgumentsAndResults(multiRunLine: line) else {
            XCTFail("Parsing failure")
            return
        }
        var results: [SingleRunResults] = []
        for _ in 0..<1000 {
            let model = StrokeModel(args.inputs)
            let result = model.run()
            results.append(result)
        }
        let multiResults = MultiRunResults(fromResults: results)
        guard let counts = multiResults.counts else {
            XCTFail("Counts not recorded")
            return
        }
        let countFromCounts = counts.values.reduce(0, +)
        XCTAssertEqual(countFromCounts, multiResults.results.count)
    }

    func testRunningMultiCenter() {
        let modelInputs = Inputs.createRandomSets(5)
        for inputs in modelInputs {
            let model = StrokeModel(inputs)
            _ = model.runWithVariance(simulationCount: 1000, useGCD: StrokeModelTests.useGCD)
        }
    }

    struct ArgumentsAndResults {
        let inputs: Inputs
        let results: Results
        let withVariance: Bool
        let csvLine: String

        // swiftlint:disable function_body_length
        init?(singleRunLine: String) {
            withVariance = false
            csvLine = singleRunLine
            let values = singleRunLine.components(separatedBy: ",")
            if values.count != 16 {
                return nil
            }

            let sexString = values[0]
            let sex: Sex
            if let sexInt = Int(sexString) {
                sex = Sex(rawValue: sexInt)!
            } else {
                let sexString = sexString
                switch sexString {
                case "Sex.FEMALE":
                    sex = .female
                case "Sex.MALE":
                    sex = .male
                default:
                    return nil
                }
            }
            let age = Int(values[1])
            let race = Double(values[2])
            let timeSinceSymptoms = Double(values[3])
            let timeToPrimary = Double(values[4])
            let timeToComprehensive = Double(values[5])
            let transferTime = Double(values[6])

            let comprehensive = StrokeCenter(comprehensiveFromFullName: "Comprehensive", time: timeToComprehensive)
            let primary = StrokeCenter(primaryFromFullName: "Primary", time: timeToPrimary,
                                       transferDestination: comprehensive, transferTime: transferTime)

            inputs = Inputs(sex: sex, age: age!, race: race!,
                            timeSinceSymptoms: timeSinceSymptoms!,
                            primaries: [primary],
                            comprehensives: [comprehensive])!

            let optimalStrategy = ArgumentsAndResults.getStrategyFromString(values[7], primary: primary,
                                                                               comprehensive: comprehensive)
            let primaryCost = Double(values[8])
            let primaryQaly = Double(values[9])
            let comprehensiveCost = Double(values[10])
            let comprehensiveQaly = Double(values[11])
            let dripAndShipCost = Double(values[12])
            let dripAndShipQaly = Double(values[13])
            let maxBenefitLocation = ArgumentsAndResults.getStrategyFromString(values[14], primary: primary,
                                                                               comprehensive: comprehensive)

            var costs = [Strategy: Double]()
            var qalys = [Strategy: Double]()
            if let primaryCost = primaryCost, primaryCost != 0.0 {
                let primStrat = Strategy(kind: .primary, center: primary)!
                costs[primStrat] = primaryCost
                qalys[primStrat] = primaryQaly!
            }
            if let comprehensiveCost = comprehensiveCost, comprehensiveCost != 0.0 {
                let compStrat = Strategy(kind: .comprehensive, center: comprehensive)!
                costs[compStrat] = comprehensiveCost
                qalys[compStrat] = comprehensiveQaly!
            }
            if let dripAndShipCost = dripAndShipCost, dripAndShipCost != 0.0 {
                let dripStrat = Strategy(kind: .dripAndShip, center: primary)!
                costs[dripStrat] = dripAndShipCost
                qalys[dripStrat] = dripAndShipQaly!
            }

            results = SingleRunResults(optimalStrategy: optimalStrategy,
                                       maxBenefit: maxBenefitLocation,
                                       costs: costs,
                                       qalys: qalys)
        }

        init?(multiRunLine: String) {
            withVariance = true
            csvLine = multiRunLine
            let values = multiRunLine.components(separatedBy: ",")
            if values.count != 11 {
                return nil
            }

            let sexString = values[0]
            let sex: Sex
            if let sexInt = Int(sexString) {
                sex = Sex(rawValue: sexInt)!
            } else {
                let sexString = sexString
                switch sexString {
                case "Sex.FEMALE":
                    sex = .female
                case "Sex.MALE":
                    sex = .male
                default:
                    return nil
                }
            }
            let age = Int(values[1])
            let race = Double(values[2])
            let timeSinceSymptoms = Double(values[3])
            let timeToPrimary = Double(values[4])
            let timeToComprehensive = Double(values[5])
            let transferTime = Double(values[6])

            let comprehensive = StrokeCenter(comprehensiveFromFullName: "Comprehensive", time: timeToComprehensive)
            let primary = StrokeCenter(primaryFromFullName: "Primary", time: timeToPrimary,
                                       transferDestination: comprehensive, transferTime: transferTime)

            inputs = Inputs(sex: sex, age: age!, race: race!,
                            timeSinceSymptoms: timeSinceSymptoms!,
                            primaries: [primary],
                            comprehensives: [comprehensive])!

            guard let percentPrimary = Double(values[7]),
                let percentComprehensive = Double(values[8]),
                let percentDripAndShip = Double(values[9]) else { return nil }
            let primStrat = Strategy(kind: .primary, center: primary)!
            let compStrat = Strategy(kind: .comprehensive, center: comprehensive)!
            let dripStrat = Strategy(kind: .dripAndShip, center: primary)!
            let percentages: [Strategy: Double] = [primStrat: percentPrimary / 100.0,
                                                   compStrat: percentComprehensive / 100.0,
                                                   dripStrat: percentDripAndShip / 100.0]
            guard let results = MultiRunResults(fromPercentages: percentages) else {
                return nil
            }
            self.results = results
        }

        static func getStrategyFromString(_ string: String, primary: StrokeCenter,
                                          comprehensive: StrokeCenter) -> Strategy? {
            switch string {
            case "Primary":
                return Strategy(kind: .primary, center: primary)
            case "Drip and Ship":
                return Strategy(kind: .dripAndShip, center: primary)
            case "Comprehensive":
                return Strategy(kind: .comprehensive, center: comprehensive)
            case "Based on cutoff":
                return nil
            default:
                fatalError("Unrecognized strategy type \(string)")
            }
        }

        func test(varyTime: Bool = true, varyLVO: Bool = true, simulationCount: Int = 25_000) {
            if withVariance {
                let model = StrokeModel(inputs)
                let modelResults = model.runWithVariance(
                    timeUncertain: varyTime,
                    lvoUncertain: varyLVO,
                    simulationCount: simulationCount,
                    useGCD: useGCD
                )
                guard let results = results as? MultiRunResults else {
                    XCTFail("Wrong results type stored")
                    return
                }
                XCTAssertEqual(modelResults, results, csvLine)
            } else {
                let model = StrokeModel(inputs)
                let singleRunResults = model.run(addTimeUncertainty: false,
                                                 addLVOuncertainty: false)
                guard let results = results as? SingleRunResults else {
                    XCTFail("Wrong results type stored")
                    return
                }
                XCTAssertEqual(singleRunResults, results, csvLine)
            }
        }
    }

    static var allTests = [
        ("testBaseCase", testBaseCase),
        ("testMany", testMany),
        ("testBaseCaseWithVariance", testBaseCaseWithVariance),
        ("testBaseCaseWithTimeVariance", testBaseCaseWithTimeVariance),
        ("testBaseCaseWithLVOVariance", testBaseCaseWithLVOVariance),
        ("testOneWithVariance", testOneWithVariance),
        ("testManyWithVariance", testManyWithVariance),
        ("testPerformance", testPerformance),
        ("testPerformanceWithVariance", testPerformanceWithVariance),
        ("testResultsSumming", testResultsSumming),
        ("testRunningMultiCenter", testRunningMultiCenter),
    ]
}
