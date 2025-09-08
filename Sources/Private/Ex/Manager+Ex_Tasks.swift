import Foundation

// MARK: - 任务管理操作
internal extension Manager {
    /// 设置存储任务
    /// - Parameter pair: 包含键和任务的元组
    func set_store_tasks(pair: (key: String, value: Task<Void, Error>)) async {
        self.store_tasks[pair.key] = pair.value
    }
    
    /// 移除存储任务
    /// - Parameter key: 要移除的任务键
    func rm_store_tasks(_ key: String) async {
        self.store_tasks.removeValue(forKey: key)
    }
    
    /// 设置读取任务
    /// - Parameter pair: 包含键和任务的元组
    func set_object_tasks(pair: (key: String, value: Any)) async {
        self.object_tasks[pair.key] = pair.value
    }
    
    /// 移除读取任务
    /// - Parameter key: 要移除的任务键
    func rm_object_tasks(_ key: String) async {
        self.object_tasks.removeValue(forKey: key)
    }
    
    /// 设置过期检查任务
    /// - Parameter pair: 包含键和任务的元组
    func set_expired_tasks(pair: (key: String, value: Task<Bool, Never>)) async {
        self.expired_tasks[pair.key] = pair.value
    }
    
    /// 移除过期检查任务
    /// - Parameter key: 要移除的任务键
    func rm_expired_tasks(_ key: String) async {
        self.expired_tasks.removeValue(forKey: key)
    }
}
