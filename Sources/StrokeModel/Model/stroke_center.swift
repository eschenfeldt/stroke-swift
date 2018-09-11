//
//  stroke_center.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/17/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

open class StrokeCenter: Hashable {

    public struct TimeDistribution {

        let firstQuartile: Double
        let median: Double
        let thirdQuartile: Double

        static let primary = TimeDistribution(firstQuartile: 47, median: 61, thirdQuartile: 83)
        static let comprehensive = TimeDistribution(firstQuartile: 39, median: 52, thirdQuartile: 70)
        static let puncture = TimeDistribution(firstQuartile: 83, median: 145, thirdQuartile: 192)
    }

    public enum CenterType {
        case primary, comprehensive
    }

    private static var nextID: Int = 1
    private static func getNextID() -> Int {
        let thisID = nextID
        nextID += 1
        return thisID
    }

    public var hashValue: Int {
        return id.hashValue
    }

    public static func == (lhs: StrokeCenter, rhs: StrokeCenter) -> Bool {
        return lhs.id == rhs.id
    }

    let id: Int
    public let centerID: Int?
    public let shortName: String
    public let fullName: String
    public let centerType: CenterType
    public var time: Double?
    public var transferDestination: StrokeCenter?
    public var transferTime: Double?
    private var dtnDist: TimeDistribution
    private var dtpDist: TimeDistribution?
//    private(set) var doorToNeedle: Double?
//    private(set) var doorToPuncture: Double?

    public var isComprehensive: Bool {
        return centerType == .comprehensive
    }

    public var isPrimary: Bool {
        return centerType == .primary
    }

    public init(fromFullName fullName: String, andShortName shortName: String,
                ofType centerType: CenterType, withCenterID centerID: Int? = nil,
                dtnDist: TimeDistribution? = nil, dtpDist: TimeDistribution? = nil) {
        self.id = StrokeCenter.getNextID()
        self.fullName = fullName
        self.shortName = shortName
        self.centerType = centerType
        self.centerID = centerID
        if let dtnDist = dtnDist {
            self.dtnDist = dtnDist
        } else {
            self.dtnDist = centerType == .primary ? .primary : .comprehensive
        }
        if let dtpDist = dtpDist {
            self.dtpDist = dtpDist
        } else if centerType == .comprehensive {
            self.dtpDist = .puncture
        } else {
            self.dtpDist = nil
        }
    }

    public convenience init(primaryFromFullName fullName: String, time: Double? = nil,
                            transferDestination: StrokeCenter? = nil, transferTime: Double? = nil) {
        self.init(fromFullName: fullName, andShortName: fullName,
                  ofType: .primary)
        self.time = time
        self.transferDestination = transferDestination
        self.transferTime = transferTime
    }

    public convenience init(comprehensiveFromFullName fullName: String, time: Double? = nil) {
        self.init(fromFullName: fullName, andShortName: fullName,
                  ofType: .comprehensive)
        self.time = time
    }

    public func addTransferDestination(_ comprehensive: StrokeCenter, transferTime: Double) {
        transferDestination = comprehensive
        self.transferTime = transferTime
    }

    func getDoorToNeedle(withUncertainty: Bool = true, performanceLevel: Double? = nil) -> Double {
        guard withUncertainty else {
            return dtnDist.median
        }
        let low = dtnDist.firstQuartile
        let high = dtnDist.thirdQuartile
        let multiplier = performanceLevel ?? Double.random()
        return low + multiplier * (high - low)
    }

    func getDoorToPuncture(withUncertainty: Bool = true, performanceLevel: Double? = nil) -> Double {
        guard let dtpDist = dtpDist else {
            fatalError("Getting door to puncture with no available distribution")
        }
        guard withUncertainty else {
            return dtpDist.median
        }
        let low = dtpDist.firstQuartile
        let high = dtpDist.thirdQuartile
        let multiplier = performanceLevel ?? Double.random()
        return low + multiplier * (high - low)
    }

}
