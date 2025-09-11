import Foundation
import CacheDataPreprocessor

// MARK: - NECache的默认实现
public extension NECache {
    static func r(
        _ localFileName: String?,
        encode: XCCacheDataPreprocessor,
        decode: XCCacheDataPreprocessor
    ) async throws -> Self? {
        if let filename = localFileName {
            try await Self._readLocal(filename, encode: encode, decode: decode)
        }
        let className = String.init(describing: type(of: self))
        let result = try await Manager.shared.object(forKey: className, as: self, encode: encode, decode: decode)
        return result
    }

    func w(
        encode: XCCacheDataPreprocessor,
        decode: XCCacheDataPreprocessor
    ) async throws {
        let className = String.init(describing: type(of: Self.self))
        try await Manager.shared.store(self, forKey: className, encode: encode, decode: decode)
    }
    
    static func expired() async -> Bool {
        let className = String.init(describing: type(of: Self.self))
        return await Manager.shared.isExpired(forKey: className)
    }
    
    static private func _readLocal(
        _ filename: String,
        encode: XCCacheDataPreprocessor,
        decode: XCCacheDataPreprocessor
    ) async throws {
        if await Manager.shared.exists(forKey: String.init(describing: type(of: self))) == false,
           let localFilePath = Bundle.main.url(forResource: filename, withExtension: nil) {
            let resourceData = try Data(contentsOf: localFilePath)
            let resourceString = String(data: resourceData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let data = Data(base64Encoded: resourceString!)
            let preprocess = try await decode.preprocess(data: data!)
            try await JSONDecoder().decode(self, from: preprocess).w(encode: encode, decode: decode)
        }
    }
}
