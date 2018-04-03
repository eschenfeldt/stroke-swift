//
//  race.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/16/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

public enum Race {

    static public func toNIHSS(race: Double) -> Double {
        var nihss: Double
        if race == 0 {
            nihss = 1.0
        } else {
            nihss = -0.39 + 2.39 * race
        }
        return nihss
    }

    static public func fromNIHSS(nihss: Double) -> Double {
        if nihss == 1.0 {
            return 0
        } else {
            return (nihss + 0.39) / 2.39
        }
    }

    public enum Palsy: Int {
        case absent = 0, mild, moderateSevere
    }

    public enum MotorImpairment: Int {
        case normalMild = 0, moderate, severe
    }

    public enum HeadAndGazeDeviation: Int {
        case absent = 0, present
    }

    public enum Hemiparesis: Int {
        case left = 0, right
    }

    public enum Agnosia: Int {
        case both = 0, one, neither
    }

    // swiftlint:disable cyclomatic_complexity
    static public func scoreFrom(palsy: Palsy, arm: MotorImpairment,
                                 leg: MotorImpairment, deviation: HeadAndGazeDeviation,
                                 agnosia: Agnosia) -> Double {
        var score = 0.0

        switch palsy {
        case .mild:
            score += 1.0
        case .moderateSevere:
            score += 2.0
        default:
            break
        }

        switch arm {
        case .moderate:
            score += 1.0
        case .severe:
            score += 2.0
        default:
            break
        }
        switch leg {
        case .moderate:
            score += 1.0
        case .severe:
            score += 2.0
        default:
            break
        }

        switch deviation {
        case .present:
            score += 1.0
        default:
            break
        }

        switch agnosia {
        case .one:
            score += 1.0
        case .neither:
            score += 2.0
        default:
            break
        }

        return score
    }

}
