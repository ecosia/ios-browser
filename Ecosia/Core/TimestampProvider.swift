import Foundation

protocol TimestampProvider {
    var currentTimestamp: TimeInterval { get }
}
