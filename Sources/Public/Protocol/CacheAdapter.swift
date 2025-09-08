// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// 键值对类型别名，包含键和值
public typealias Pair<K: Hashable, V> = (k: K, v: V)

/// 缓存适配器协议
/// 定义了统一的缓存操作接口，支持异步操作
/// 使用关联类型来约束键和值的类型
public protocol CacheAdapter {
    /// 键的类型，必须可哈希
    associatedtype K: Hashable
    /// 值的类型
    associatedtype V
    
    /// 异步存储键值对到缓存
    /// - Parameter pair: 包含键和值的元组
    /// - Throws: 存储失败时抛出异常
    func set(_ pair: Pair<K, V>) async throws
    
    /// 异步根据键获取缓存中的键值对
    /// - Parameter key: 要查找的键
    /// - Returns: 包含键和值的元组
    /// - Throws: 获取失败或键不存在时抛出异常
    func get(forKey key: K) async throws -> Pair<K, V>
    
    /// 异步检查指定键是否存在于缓存中
    /// - Parameter key: 要检查的键
    /// - Returns: 存在返回 true，否则返回 false
    func exists(forKey key: K) async -> Bool
    
    /// 异步从缓存中移除指定键的数据
    /// - Parameter key: 要移除的键
    /// - Throws: 移除失败时抛出异常
    func rm(forKey key: K) async throws
}
