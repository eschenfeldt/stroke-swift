//
//  stroke_center.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/17/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

open class StrokeCenter: Hashable {

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
    public let shortName: String
    public let fullName: String
    public let centerType: CenterType
    public var time: Double?
    public var transferDestination: StrokeCenter?
    public var transferTime: Double?

    public var isComprehensive: Bool {
        return centerType == .comprehensive
    }

    public var isPrimary: Bool {
        return centerType == .primary
    }

    public init(fromFullName fullName: String, andShortName shortName: String,
                ofType centerType: CenterType) {
        self.id = StrokeCenter.getNextID()
        self.fullName = fullName
        self.shortName = shortName
        self.centerType = centerType
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

}
