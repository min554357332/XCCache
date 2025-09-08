import Foundation
import Cache

/// 网络缓存管理器
/// 基于 actor 的线程安全缓存管理实现，支持异步操作
/// 提供对象的存储、读取、过期检查等功能
/// 支持 AES 加密存储，确保数据安全
final internal actor Manager {
    /// 单例实例
    internal static let shared = Manager()
    
    /// 底层存储，使用 Cache 库的 Storage
    /// 标记为 nonisolated(unsafe) 因为我们通过任务管理机制来确保并发安全
    internal nonisolated(unsafe) let storage: Storage<String, Data>
    
    /// 缓存过期时间（秒），默认 600 秒（10分钟）
    internal let expiry: Int = 600
    
    /// 存储写入任务字典，用于管理并发写入操作
    /// Key: 缓存键，Value: 写入任务
    internal var store_tasks: [String: Task<Void, Error>] = [:]
    
    /// 存储读取任务字典，用于管理并发读取操作
    /// Key: 缓存键，Value: 读取任务（类型擦除为 Any）
    internal var object_tasks: [String: Any] = [:]
    
    /// 存储过期检查任务字典，用于管理并发过期检查操作
    /// Key: 缓存键，Value: 过期检查任务
    internal var expired_tasks: [String: Task<Bool, Never>] = [:]
    
    /// 私有初始化方法，配置底层存储
    /// 使用磁盘存储配置和内存存储配置创建 Storage 实例
    private init() {
        do {
            // 创建磁盘和内存混合存储，数据持久化到磁盘
            self.storage = try Storage<String, Data>(
                diskConfig: DiskConfig(name: "SuperVPNFly_Cache"), // 磁盘缓存名称
                memoryConfig: MemoryConfig(expiry: .never),        // 内存缓存永不过期（由自定义逻辑控制）
                fileManager: FileManager.default,                  // 使用默认文件管理器
                transformer: TransformerFactory.forData()          // 数据转换器
            )
        } catch {
            fatalError("Failed to initialize cache: \(error)")
        }
    }
}
