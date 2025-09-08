import Foundation
//import AES

// MARK: - NECache的默认实现
public extension NECache {
    static func r(_ localFileName: String) async throws -> Self {
        try await Self._readLocal(localFileName)
        let className = String.init(describing: type(of: self))
        let result = try await Manager.shared.object(forKey: className, as: self)
        return result
    }
    
    func w() async throws {
        let className = String.init(describing: type(of: Self.self))
        try await Manager.shared.store(self, forKey: className)
    }
    
    static func expired() async -> Bool {
        let className = String.init(describing: type(of: Self.self))
        return await Manager.shared.isExpired(forKey: className)
    }
    
    static private func _readLocal(_ filename: String) async throws {
        if await Manager.shared.exists(forKey: String.init(describing: type(of: self))) == false,
           let localFilePath = Bundle.main.url(forResource: filename, withExtension: nil) {
            let data = try Data(contentsOf: localFilePath)
//            let aes_decrypt_result: Result<Data, AES.Err> = AES.decrypt(data)
//            switch aes_decrypt_result {
//            case .success(let success):
//                let obj = try JSONDecoder().decode(self, from: success)
//                try await obj.w()
//            case .failure(let failure):
//                throw failure
//            }
            try await JSONDecoder().decode(self, from: data).w()
        }
    }
}
