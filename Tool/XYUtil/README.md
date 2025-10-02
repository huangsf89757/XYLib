# XYUtil

[![CI Status](https://img.shields.io/travis/hsf89757/XYUtil.svg?style=flat)](https://travis-ci.org/hsf89757/XYUtil)
[![Version](https://img.shields.io/cocoapods/v/XYUtil.svg?style=flat)](https://cocoapods.org/pods/XYUtil)
[![License](https://img.shields.io/cocoapods/l/XYUtil.svg?style=flat)](https://cocoapods.org/pods/XYUtil)
[![Platform](https://img.shields.io/cocoapods/p/XYUtil.svg?style=flat)](https://cocoapods.org/pods/XYUtil)

## 目录

<details>
<summary>点击展开目录</summary>

- [XYUtil](#xyutil)
  - [目录](#目录)
  - [项目概述](#项目概述)
  - [功能模块](#功能模块)
    - [通用工具](#通用工具)
      - [XYApp](#xyapp)
      - [XYUtil](#xyutil-1)
    - [属性包装器](#属性包装器)
      - [XYThreadSafeProperty](#xythreadsafeproperty)
      - [XYThreadSafeObservableProperty](#xythreadsafeobservableproperty)
      - [XYStateObservableProperty](#xystateobservableproperty)
      - [XYAtomicCounter](#xyatomiccounter)
      - [XYAtomicFlag](#xyatomicflag)
      - [功能对比](#功能对比)
  - [安装说明](#安装说明)
  - [使用示例](#使用示例)
  - [作者信息](#作者信息)
  - [许可证](#许可证)

</details>

## 项目概述

XYUtil 是一个 iOS 开发工具库，旨在为开发者提供实用的工具方法，简化开发流程。该库包含应用信息获取、线程安全属性包装器和原子操作类等模块，可帮助开发者更轻松地处理常见的 iOS 开发任务。

## 功能模块

### 通用工具
#### XYApp 

提供便捷的应用信息获取功能，包括：

- `bundleId`: 获取应用 Bundle ID
- `name`: 获取应用名称
- `version`: 获取应用版本号
- `build`: 获取应用构建号
- `logo`: 获取应用图标

```swift
// 使用示例
print("App名称: \(XYApp.name)")
print("版本号: \(XYApp.version)")
print("构建号: \(XYApp.build)")
if let icon = XYApp.logo {
    // 使用应用图标
}
```

#### XYUtil

核心模块提供基础类型定义和通用工具：

- `XYIdentifier`: 类型别名，用于标识符字符串类型

```swift
// 使用示例
let userId: XYIdentifier = "user_123456"
```

### 属性包装器

属性包装器是一组用于简化线程安全和状态管理的工具类。

#### XYThreadSafeProperty

> 基础线程安全属性包装器

**功能特点**：
- **线程安全**：使用并发队列保护属性访问
- **自动同步**：读取时同步，写入时使用屏障确保原子性
- **简单易用**：像普通属性一样使用，但具有线程安全特性

**适用情况**：
- 需要在线程间共享的基本类型数据
- 不需要观察变化的属性
- 频繁读取但偶尔写入的场景

**使用示例**：
```swift
class Counter {
    @XYThreadSafeProperty var count: Int = 0
    @XYThreadSafeProperty var name: String = ""
    
    func increment() {
        // 线程安全的递增操作
        count += 1
    }
    
    func updateName(_ newName: String) {
        // 线程安全的赋值操作
        name = newName
    }
    
    func complexOperation() {
        // 复杂操作需要使用 withLock 保证原子性
        $count.withLock { value in
            value += 10
            value *= 2
        }
    }
}
```

#### XYThreadSafeObservableProperty

> 线程安全可观察属性包装器

**功能特点**：
- **线程安全** + **变化通知**：既保证线程安全，又支持状态变化监听
- **观察者模式**：支持添加多个观察者
- **自动通知**：属性变化时自动通知所有观察者

**适用情况**：
- 需要监控状态变化的属性
- 需要响应属性变化的 UI 更新
- 多组件间需要同步状态的场景

**使用示例**：
```swift
class NetworkManager {
    @XYThreadSafeObservableProperty var isConnected: Bool = false
    @XYThreadSafeObservableProperty var downloadProgress: Double = 0.0
    
    init() {
        // 添加观察者
        $isConnected.addObserver { oldValue, newValue in
            print("网络状态变化: \(oldValue) -> \(newValue)")
        }
        
        $downloadProgress.addObserver { oldValue, newValue in
            print("下载进度: \(oldValue) -> \(newValue)")
        }
    }
    
    func connect() {
        isConnected = true  // 会触发观察者回调
    }
    
    func updateProgress(_ progress: Double) {
        downloadProgress = progress  // 会触发观察者回调
    }
}
```

#### XYStateObservableProperty

> 状态变化通知属性包装器

**功能特点**：
- **只在值变化时通知**：只有当新值与旧值不相等时才触发观察者
- **Equatable 约束**：只适用于遵循 Equatable 协议的类型
- **避免冗余通知**：防止相同值赋值时的无效通知
- **自动内存管理**：使用弱引用避免循环引用

**适用情况**：
- 状态管理（如网络状态、加载状态等）
- 避免重复状态变化通知的场景
- 性能敏感的频繁赋值场景

**使用示例**：
```swift
enum LoadState: Equatable {
    case idle, loading, success, failed
}

class DataLoader {
    @XYStateObservableProperty var state: LoadState = .idle
    
    init() {
        // 使用上下文关联观察者，自动管理内存
        $state.addObserver(for: self) { oldState, newState in
            print("状态变化: \(oldState) -> \(newState)")
        }
    }
    
    func loadData() {
        state = .loading  // 通知: idle -> loading
        state = .loading  // 不通知（值相同）
        state = .success  // 通知: loading -> success
        state = .success  // 不通知（值相同）
    }
}
```


#### XYAtomicCounter

> 原子计数器

**功能特点**：
- **原子操作**：保证计数操作的原子性
- **线程安全**：多线程同时操作不会出现竞争条件
- **多种操作**：支持增减、加减、重置等操作

**适用情况**：
- 统计操作次数
- 并发任务计数
- 进度跟踪等需要原子操作的场景

**使用示例**：
```swift
class TaskManager {
    private let activeTaskCounter = XYAtomicCounter()
    private let completedTaskCounter = XYAtomicCounter()
    
    func startTask() {
        let currentActive = activeTaskCounter.increment()
        print("开始任务，当前活跃任务数: \(currentActive)")
    }
    
    func completeTask() {
        let completed = completedTaskCounter.increment()
        let active = activeTaskCounter.decrement()
        print("完成任务，已完成: \(completed)，活跃: \(active)")
    }
    
    func getTotalTasks() -> Int {
        return activeTaskCounter.current + completedTaskCounter.current
    }
}
```

#### XYAtomicFlag

> 原子布尔标志

**功能特点**：
- **原子布尔操作**：设置、重置、切换、比较并设置等
- **线程安全**：保证标志位操作的原子性
- **CAS 操作**：提供 compareAndSet 方法进行条件更新

**适用情况**：
- 开关控制（如启动/停止标志）
- 条件同步
- 状态标记等布尔值场景

**使用示例**：
```swift
class ServiceManager {
    private let isRunning = XYAtomicFlag(value: false)
    private let isInitialized = XYAtomicFlag(value: false)
    
    func start() {
        // 使用 compareAndSet 确保只启动一次
        if isRunning.compareAndSet(expected: false, newValue: true) {
            print("服务启动")
            initialize()
        } else {
            print("服务已在运行")
        }
    }
    
    private func initialize() {
        if isInitialized.compareAndSet(expected: false, newValue: true) {
            print("初始化服务")
        }
    }
    
    func stop() {
        if isRunning.compareAndSet(expected: true, newValue: false) {
            print("服务停止")
        }
    }
}
```

#### 功能对比

| 类 | 线程安全 | 观察者模式 | 值变化检查 | 自动内存管理 |
|---|:---:|:---:|:---:|:---:|
| XYThreadSafeProperty | ✅ | ❌ | ❌ | ❌ |
| XYThreadSafeObservableProperty | ✅ | ✅ | ❌ | ❌ |
| XYStateObservableProperty | ✅ | ✅ | ✅ | ✅ |
| XYAtomicCounter | ✅ | ❌ | ❌ | ❌ |
| XYAtomicFlag | ✅ | ❌ | ❌ | ❌ |

## 安装说明

XYUtil 可通过 [CocoaPods](https://cocoapods.org) 安装。在你的 Podfile 中添加以下行：

```ruby
pod 'XYUtil'
```

然后运行 `pod install` 命令。

## 使用示例

要运行示例项目，请先克隆仓库，然后进入 Example 目录并运行 `pod install`。

## 作者信息

hsf89757, hsf89757@gmail.com

## 许可证

XYUtil 基于 MIT 许可证发布。有关详细信息，请参阅 LICENSE 文件。