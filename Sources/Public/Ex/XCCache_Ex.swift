import Foundation
import CacheDataPreprocessor

// MARK: - NECache的默认实现
public extension NECache {
    static func r(_ localFileName: String, dataPreprocessor: XCCacheDataPreprocessor) async throws -> Self {
        try await Self._readLocal(localFileName, dataPreprocessor: dataPreprocessor)
        let className = String.init(describing: type(of: self))
        let result = try await Manager.shared.object(forKey: className, as: self, dataPreprocessor: dataPreprocessor)
        return result
    }

    func w(dataPreprocessor: XCCacheDataPreprocessor) async throws {
        let className = String.init(describing: type(of: Self.self))
        try await Manager.shared.store(self, forKey: className, dataPreprocessor: dataPreprocessor)
    }
    
    static func expired() async -> Bool {
        let className = String.init(describing: type(of: Self.self))
        return await Manager.shared.isExpired(forKey: className)
    }
    
    static private func _readLocal(_ filename: String, dataPreprocessor: XCCacheDataPreprocessor) async throws {
        if await Manager.shared.exists(forKey: String.init(describing: type(of: self))) == false,
           let localFilePath = Bundle.main.url(forResource: filename, withExtension: nil) {
            let data = try Data(contentsOf: localFilePath)
            try await JSONDecoder().decode(self, from: data).w(dataPreprocessor: dataPreprocessor)
        }
    }
}
