import Foundation

public protocol NECache: Codable, Sendable {
    static func r(_ filename: String) async throws -> Self
    func w() async throws
    static func expired() async -> Bool
}

