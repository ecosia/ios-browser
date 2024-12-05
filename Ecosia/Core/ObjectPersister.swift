import Foundation

protocol ObjectPersister {
    func set(_ value: Any?, forKey: String)
    func object(forKey: String) -> Any?
}
