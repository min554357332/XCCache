import Foundation
import CacheDataPreprocessor

public protocol NECache: Codable, Sendable {
    static func r(_ filename: String, dataPreprocessor: XCCacheDataPreprocessor) async throws -> Self
    func w(dataPreprocessor: XCCacheDataPreprocessor) async throws
    static func expired() async -> Bool
}

