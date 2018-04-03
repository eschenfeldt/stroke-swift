import XCTest

import StrokeModelTests

Glibc.srandom(UInt32(Glibc.time(nil)))

var tests = [XCTestCaseEntry]()
tests += StrokeModelTests.allTests()
XCTMain(tests)
