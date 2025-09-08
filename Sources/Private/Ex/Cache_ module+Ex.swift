import Foundation
import Cache


/// Storage 扩展，实现 CacheAdapter 协议
/// 将 Cache 库的 Storage 适配为统一的缓存接口
extension Storage: CacheAdapter {
    /// 键类型别名，使用 Storage 的 Key 类型
    public typealias K = Key
    /// 值类型别名，使用 Storage 的 Value 类型
    public typealias V = Value
    
    /// 异步写入缓存（约束为当前 Storage 的 Key / Value）
    /// - Parameter pair: 包含键和值的元组
    /// - Throws: 存储失败时抛出异常
    public func set(_ pair: Pair<K, V>) async throws {
        try self.setObject(pair.v, forKey: pair.k, expiry: .never)
    }
    
    /// 异步获取缓存
    /// - Parameter key: 要查找的键
    /// - Returns: 包含键和值的元组
    /// - Throws: 获取失败或键不存在时抛出异常
    public func get(forKey key: K) async throws -> Pair<K, V> {
        return (k: key, v: try self.object(forKey: key))
    }
    
    /// 异步判断指定键是否存在
    /// - Parameter key: 要检查的键
    /// - Returns: 存在返回 true，否则返回 false
    public func exists(forKey key: K) async -> Bool {
        return self.objectExists(forKey: key)
    }
    
    /// 异步移除指定键的缓存数据
    /// - Parameter key: 要移除的键
    /// - Throws: 移除失败时抛出异常
    public func rm(forKey key: K) async throws {
        try self.removeObject(forKey: key)
    }
}

