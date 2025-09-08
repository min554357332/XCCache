import Foundation

public protocol XCCacheDataPreprocessor: Sendable {
    func preprocess(data: Data) async throws -> Data
}
