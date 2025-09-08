import Foundation
//import AES

internal extension Manager {
    /// 异步存储对象到缓存
    /// 支持并发控制，如果同一个 key 正在进行存储操作，会等待完成后再执行新的存储
    /// - Parameters:
    ///   - object: 要存储的对象，必须遵循 NECache 协议
    ///   - key: 存储键
    /// - Throws: 存储失败时抛出异常
    func store<T: NECache>(_ object: T, forKey key: String) async throws {
        // 如果有正在进行的存储任务，等待完成
        if let existingTask = self.store_tasks[key] {
            try await existingTask.value
        }
        let task = Task {
            do {
                try await self._store(object, forKey: key)
                await self.rm_store_tasks(key)
            } catch {
                await self.rm_store_tasks(key)
                throw error
            }
        }
        await self.set_store_tasks(pair: (key, task))
        try await task.value
    }
    
    /// 异步从缓存中获取对象
    /// 支持并发控制，会取消正在进行的同 key 读取任务，以最新的读取请求为准
    /// - Parameters:
    ///   - key: 要查找的键
    ///   - type: 目标对象类型
    /// - Returns: 解码后的对象
    /// - Throws: 获取失败、解密失败或解码失败时抛出异常
    func object<T: NECache>(forKey key: String, as type: T.Type) async throws -> T {
        // 如果有正在进行的存储任务，等待完成
        if let existingTask = self.store_tasks[key] {
            try await existingTask.value
        }
        // 如果有正在进行的读取任务，取消任务, 以最新的读取任务为准
        if let existingTask = self.object_tasks[key] as? Task<T, Error> {
            await self.rm_object_tasks(key)
            existingTask.cancel()
        }
        let task = Task<T, Error> {
            do {
                let result = try await self._object(forKey: key, as: type)
                await self.rm_object_tasks(key)
                return result
            } catch {
                await self.rm_object_tasks(key)
                throw error
            }
        }
        await self.set_object_tasks(pair: (key, task))
        return try await task.value
    }
    
    /// 异步检查指定键的缓存是否已过期
    /// 会等待正在进行的存储和过期检查任务完成
    /// - Parameter key: 要检查的键
    /// - Returns: 过期返回 true，未过期返回 false
    func isExpired(forKey key: String) async -> Bool {
        // 如果有正在进行的存储任务，等待完成
        if let existingTask = self.store_tasks[key] {
            try? await existingTask.value
        }
        // 如果有正在进行的判断过期任务，取消任务
        if let existingTask = self.expired_tasks[key] {
            await self.rm_expired_tasks(key)
            existingTask.cancel()
        }
        let task = Task {
            let result = await self._isExpired(forKey: key)
            await self.rm_expired_tasks(key)
            return result
        }
        await self.set_expired_tasks(pair: (key, task))
        return await task.value
    }
    
    /// 异步检查指定键是否存在于缓存中
    /// - Parameter key: 要检查的键
    /// - Returns: 存在返回 true，不存在返回 false
    func exists(forKey key: String) async -> Bool {
        // 如果有正在进行的存储任务，等待完成
        if let existingTask = self.store_tasks[key] {
            try? await existingTask.value
        }
        return await self.storage.exists(forKey: key)
    }
}

// MARK: - 基本缓存操作
private extension Manager {
    /// 内部异步存储对象到缓存的实现
    /// 包含完整的加密、编码和存储流程
    /// - Parameters:
    ///   - object: 要存储的对象
    ///   - key: 存储键
    /// - Throws: 编码、加密或存储失败时抛出异常
    func _store<T: NECache>(_ object: T, forKey key: String) async throws {
        // 先删除可能存在的旧数据（无论是否存在都尝试删除，避免竞争条件）
        try? await self.storage.rm(forKey: key)
        try? await self.storage.rm(forKey: "\(key)_expiry_info")
        
//        let data = try JSONEncoder().encode(object).base64EncodedData()
//        let aes_data_encrypt_result = AES.encrypt(data)
//        switch aes_data_encrypt_result {
//        case .success(let success):
//            if let result = success.toData() {
//                try await self.storage.set((k: key, v: result))
//                let timestamp = Int(Date().addingTimeInterval(TimeInterval(self.expiry)).timeIntervalSince1970)
//                let expiryTimestamp = "\(timestamp)".data(using: .utf8)!
//                try await self.storage.set((k: "\(key)_expiry_info", v: expiryTimestamp))
//            } else {
//                throw NSError(domain: "Err", code: -1)
//            }
//        case .failure(let failure):
//            throw failure
//        }
        let data = try JSONEncoder().encode(object)
        try await self.storage.set((k: key, v: data))
        let timestamp = "\(Int(Date().addingTimeInterval(TimeInterval(self.expiry)).timeIntervalSince1970))".data(using: .utf8)!
        try await self.storage.set((k: "\(key)_expiry_info", v: timestamp))
        
    }
    
    /// 内部异步从缓存中获取对象的实现
    /// 包含完整的读取、解密和解码流程
    /// - Parameters:
    ///   - key: 要查找的键
    ///   - type: 目标对象类型
    /// - Returns: 解码后的对象
    /// - Throws: 读取、解密或解码失败时抛出异常
    func _object<T: NECache>(forKey key: String, as type: T.Type) async throws -> T {
        let pair = try await self.storage.get(forKey: key)
//        let aes_data_decrypt_result: Result<Data, AES.Err> = AES.decrypt(pair.v)
//        switch aes_data_decrypt_result {
//        case .success(let success):
//            let model = try JSONDecoder().decode(type, from: success)
//            return model
//        case .failure(let failure):
//            throw failure
//        }
        let model = try JSONDecoder().decode(type, from: pair.v)
        return model
    }
    
    /// 内部检查指定 key 的缓存是否已过期的实现
    /// 通过比较存储的过期时间戳与当前时间来判断是否过期
    /// - Parameter key: 要检查的键
    /// - Returns: 过期返回 true，未过期返回 false，找不到缓存或时间戳也返回 true
    func _isExpired(forKey key: String) async -> Bool {
        // 直接尝试获取过期时间信息，如果失败则认为已过期
        guard let expiryPair = try? await self.storage.get(forKey: "\(key)_expiry_info"),
              let expiryStr = String(data: expiryPair.v, encoding: .utf8),
              let expiryInt = Int(expiryStr) else {
            return true
        }
        
        // 再次确认主数据是否存在，防止数据不一致
        guard await self.storage.exists(forKey: key) else {
            return true
        }
        
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiryInt))
        return Date() > expiryDate
    }
}
