// Wayfinder

enum BestWorst: String, CaseIterable, Identifiable {
    case best
    case worst
    
    var id: String { self.rawValue }
}

protocol MetricComparable {
    var engagement: Int64 { get }
    var energy: Int64 { get }
}

enum Metric: String, CaseIterable, Identifiable {
    case combined
    case engagement
    case energy
    
    var id: String { self.rawValue }
    
    private var areInIncreasingOrder: (MetricComparable, MetricComparable) -> Bool {
        switch self {
        case .engagement:
            return {$0.engagement > $1.engagement}
        case .energy:
            return {$0.energy > $1.energy}
        case .combined:
            return {$0.engagement + $0.energy > $1.engagement + $1.energy}
        }
    }
    
    func makeComparator(direction bestWorst: BestWorst) -> ((MetricComparable, MetricComparable) -> Bool) {
        switch bestWorst {
        case .best:
            return areInIncreasingOrder
        case .worst:
            return {!areInIncreasingOrder($0, $1)}
        }
    }
}
