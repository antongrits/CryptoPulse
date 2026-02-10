import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case offline
    case rateLimited(retryAfter: TimeInterval?)
    case server(statusCode: Int)
    case decoding
    case unknown

    var errorDescription: String? {
        switch self {
        case .offline:
            return NSLocalizedString("No internet connection.", comment: "")
        case .rateLimited:
            return NSLocalizedString("Too many requests. Please try again later.", comment: "")
        case .server(let statusCode):
            if statusCode == 400 {
                return NSLocalizedString("Request not supported for this plan.", comment: "")
            }
            let format = NSLocalizedString("Server error (%d).", comment: "")
            return String(format: format, statusCode)
        case .decoding:
            return NSLocalizedString("Failed to parse server response.", comment: "")
        case .unknown:
            return NSLocalizedString("Unexpected error.", comment: "")
        }
    }
}
