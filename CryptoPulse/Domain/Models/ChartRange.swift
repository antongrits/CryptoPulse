import Foundation

enum ChartRange: String, CaseIterable, Identifiable {
    case oneDay = "1D"
    case sevenDays = "7D"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
    case all = "ALL"

    var id: String { rawValue }

    var title: String {
        rawValue
    }

    var daysQueryValue: String {
        switch self {
        case .oneDay: return "1"
        case .sevenDays: return "7"
        case .oneMonth: return "30"
        case .threeMonths: return "90"
        case .oneYear: return "365"
        case .all: return "max"
        }
    }

    var axisDateStyle: DateFormatter {
        let f = DateFormatter()
        switch self {
        case .oneDay:
            f.dateFormat = "HH:mm"
        case .sevenDays, .oneMonth:
            f.dateFormat = "MMM d"
        case .threeMonths, .oneYear, .all:
            f.dateFormat = "MMM yy"
        }
        return f
    }
}
