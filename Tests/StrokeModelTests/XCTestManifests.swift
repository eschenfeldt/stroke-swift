import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(StrokeModelTests.allTests),
        testCase(RandomTests.allTests),
        testCase(ResultsTests.allTests)
    ]
}
#endif
