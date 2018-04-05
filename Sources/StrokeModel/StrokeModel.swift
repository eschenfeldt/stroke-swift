import Dispatch

public final class StrokeModel {

    let thresholdICER: Double
    let modelInputs: Inputs

    public init(_ inputs: Inputs, thresholdICER: Double = 100_000.0) {
        self.modelInputs = inputs
        self.thresholdICER = thresholdICER
    }

    public func run(addTimeUncertainty: Bool = true,
                    addLVOuncertainty: Bool = true) -> SingleRunResults {

        Costs.shared.inflate(targetYear: 2016)

        let aisModel = IschemicModel(modelInputs, addTimeUncertainty: addTimeUncertainty,
                                     addLVOuncertainty: addLVOuncertainty)

        if !aisModel.modelIsNecessary {
            return SingleRunResults(optimalLocation: aisModel.cutoffLocation,
                                    maxBenefit: nil, costs: [:], qalys: [:])
        }

        let strategiesToRun: [Strategy] = modelInputs.strategies
        var costs = [Strategy: Double]()
        var qalys = [Strategy: Double]()
        var usedStrategies = [Strategy]()
        var maxQaly: (strategy: Strategy?, qaly: Double) = (strategy: nil, qaly: 0.0)
        for strategy in strategiesToRun {
            guard let ischemicOutcomes = aisModel.getAISoutcomes(key: strategy) else {
                continue
            }
            let markovedPopulation = Population(aisModel: aisModel,
                                                 aisOutcome: ischemicOutcomes,
                                                 simtype: strategy)
            markovedPopulation.analyze()
            let qaly = markovedPopulation.qalys!
            costs[strategy] = markovedPopulation.costs!
            qalys[strategy] = qaly
            usedStrategies.append(strategy)
            if qaly > maxQaly.qaly {
                maxQaly.strategy = strategy
                maxQaly.qaly = qaly
            }
        }

        var results = SingleRunResults(optimalLocation: nil,
                                       maxBenefit: maxQaly.strategy,
                                       costs: costs, qalys: qalys)
        results.get_optimal(strategies: usedStrategies,
                            threshold: thresholdICER)

        return results
    }

    class RunningResults {

        private let runningResultsQueue = DispatchQueue(label: "org.mgh-ita.StrokeModel.Results",
                                                        attributes: .concurrent)
        private var _results: [SingleRunResults] = []
        var totalToRun: Int

        var results: [SingleRunResults] {
            return runningResultsQueue.sync {
                return _results
            }
        }
        var count: Int {
            return results.count
        }
        var percentage: Float {
            return Float(count) / Float(totalToRun)
        }
        private var doneOrWaiting: Int = 0
        var doneOrWaitingPercentage: Float {
            return Float(doneOrWaiting) / Float(totalToRun)
        }

        init(total: Int) {
            totalToRun = total
        }

        func addResults(_ newResults: [SingleRunResults],
                        progressUpdate: (() -> Void)? = nil) {
            doneOrWaiting += newResults.count
            runningResultsQueue.async(flags: .barrier) {
                self._results.append(contentsOf: newResults)
            }
        }

        func partialPercentage(_ newCount: Int) -> Float {
            return Float(count + newCount) / Float(totalToRun)
        }

    }

    public func runWithVariance(timeUncertain: Bool = true,
                                lvoUncertain: Bool = true,
                                simulationCount n: Int = 1000,
                                progressHandler: ((Int) -> Void)? = nil,
                                completionHandler: ((MultiRunResults, Error?) -> Void)? = nil,
                                useGCD: Bool = true) -> MultiRunResults {

        Costs.shared.inflate(targetYear: 2016)

        let results = RunningResults(total: n)
        let out: MultiRunResults
        if useGCD {
            DispatchQueue.concurrentPerform(iterations: n) { i in
                let thisRun = run(addTimeUncertainty: timeUncertain,
                                  addLVOuncertainty: lvoUncertain)
                results.addResults([thisRun])
                if let progressHandler = progressHandler {
                    progressHandler(i)
                }
            }
            out = MultiRunResults(fromResults: results.results)
        } else {
            var resultsList: [SingleRunResults] = []
            for i in 1...n {
                resultsList.append(run(addTimeUncertainty: timeUncertain, addLVOuncertainty: lvoUncertain))
                if let progressHandler = progressHandler {
                    progressHandler(i)
                }
            }
            out = MultiRunResults(fromResults: resultsList)
        }
        if let completionHandler = completionHandler {
            completionHandler(out, nil)
        }
        return out
    }

}

extension StrokeCenter {
    convenience init(primaryFromTime time: Double, transferTime: Double, index: Int = 1) {
        let destination = StrokeCenter(comprehensiveFromFullName: "Destination \(index)")
        self.init(primaryFromFullName: "Primary \(index)", time: time, transferDestination: destination,
                  transferTime: transferTime)
    }
    convenience init(comprehensiveFromTime time: Double, index: Int = 1) {
        self.init(comprehensiveFromFullName: "Comprehensive \(index)", time: time)
    }
}
