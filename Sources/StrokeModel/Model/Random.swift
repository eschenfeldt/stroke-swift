//
//  Random.swift
//  StrokeModel
//
//  Created by Patrick Eschenfeldt (ITA) on 3/30/18.
//

import Foundation

extension Int {

    static func random(below end: Int) -> Int {
        guard end >= 0 else {
            fatalError("This function is for random nonnegative integers")
        }
        #if !os(Linux)
        return Int(arc4random_uniform(UInt32(end)))
        #else
        return Glibc.random() % end
        #endif
    }
}

extension Double {

    // Generates a uniform random Double in [0,1]
    static func random() -> Double {
        #if !os(Linux)
        return Double(arc4random()) / Double(UInt32.max)
        #else
        return Double(Glibc.random()) / Double(Glibc.RAND_MAX)
        #endif
    }

}
