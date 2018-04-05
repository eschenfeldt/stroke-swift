//
//  optimal_strategy.swift
//  Stroke
//
//  Created by Patrick Eschenfeldt (ITA) on 10/3/17.
//  Copyright © 2017 MGH Institute for Technology Assessment. All rights reserved.
//

extension SingleRunResults {

    // MARK: Finding Optimal
    func format(strategies: [Strategy]) -> [FormattedResult] {
        var data = [FormattedResult]()
        for label in strategies {
            let cost = costs[label]!
            let qaly = qalys[label]!
            data.append(FormattedResult(strategy: label, qaly: qaly,
                                        cost: cost, icer: nil))
        }
        return data
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    mutating func get_optimal(strategies: [Strategy], threshold: Double) {

        var data = format(strategies: strategies)

        data.sort(by: {(fr1: FormattedResult, fr2: FormattedResult) -> Bool in
            return (fr1.qaly < fr2.qaly ||
                    (fr1.qaly == fr2.qaly && fr1.cost < fr2.cost))
        })

        while true {
            var end = false
            let count = data.count
            for i in 0..<count {
                if i == count - 1 {
                    end = true
                    break
                } else {
                    let this = data[i]
                    let next = data[i + 1]
                    if this.qaly >= next.qaly && this.cost < next.cost {
                        data.remove(at: i + 1)
                        break
                    }
                }
            }
            if end {
                break
            }
        }

        if data.count <= 1 {
            // We've found the optimal strategy just by checking domination
            optimalStrategy = data[0].strategy
            return
        }

        // Otherwise we need to compute ICERs narrow them down to the best one
        while true {
            var end = false
            let icers = get_icers(data: data)
            for i in icers.indices {
                if i == icers.count - 1 {
                    end = true
                    break
                } else {
                    if icers[i] > icers[i + 1] {
                        data.remove(at: i + 1)
                        break
                    }
                }
            }
            if end {
                for i in data.indices {
                    if i == 0 { continue }
                    data[i].icer = icers[i - 1]
                }
                break
            }
        }

        for thisData in data.reversed() {
            if thisData.icer == nil {
                optimalStrategy = thisData.strategy
                return
            } else if thisData.icer! < threshold {
                optimalStrategy = thisData.strategy
                return
            }
        }
    }

}

struct FormattedResult {
    let strategy: Strategy
    let qaly: Double
    let cost: Double
    var icer: Double?
}

func get_icers(data: [FormattedResult]) -> [Double] {
    var icers = [Double]()
    for i in data.indices {
        if i == 0 {
            continue
        }
        let num = data[i].cost - data[i - 1].cost
        let den = data[i].qaly - data[i - 1].qaly
        icers.append(num / den)
    }
    return icers
}
