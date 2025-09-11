import Foundation
import CacheDataPreprocessor

public protocol NECache: Codable, Sendable {
    static func r(
        _ filename: String?,
        encode: XCCacheDataPreprocessor,
        decode: XCCacheDataPreprocessor
    ) async throws -> Self?
    
    func w(
        encode: XCCacheDataPreprocessor,
        decode: XCCacheDataPreprocessor
    ) async throws
    
    static func expired() async -> Bool
}

