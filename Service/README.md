# Server Components

Server 组件封装了 XYLib 的基础服务功能，包括网络请求、蓝牙通信、日志系统、数据存储等。

## 组件列表

### XYCoreBluetooth
封装 CoreBluetooth 功能，用于蓝牙设备通信。

### XYLog
日志系统封装，集成 CocoaLumberjack。

### XYNetwork
网络请求模块，基于 URLSession 或 Alamofire 封装。

### XYStorage
本地数据持久化模块（UserDefaults/Keychain/File）。

### XYWatchConnectivity
Apple Watch 通信支持。

## 架构图

```mermaid
graph TD
    A[Server 组件] --> B[XYCoreBluetooth]
    A --> C[XYLog]
    A --> D[XYNetwork]
    A --> E[XYStorage]
    A --> F[XYWatchConnectivity]
    
    subgraph Server
        B
        C
        D
        E
        F
    end
    
    style A fill:#FFA07A,stroke:#333
    style B fill:#FFE4B5,stroke:#333
    style C fill:#FFE4B5,stroke:#333
    style D fill:#FFE4B5,stroke:#333
    style E fill:#FFE4B5,stroke:#333
    style F fill:#FFE4B5,stroke:#333
```

## 依赖关系

Server 组件内部各模块的依赖关系：

```mermaid
graph TD
    A[XYCoreBluetooth] --> B[XYLog]
    A --> C[XYCmd]
    
    D[XYWatchConnectivity] --> B
    
    E[XYStorage] --> F[XYUtil]
    
    G[XYNetwork] --> F
    
    H[XYLog] --> F
    H --> I[CocoaLumberjack]
    
    C --> B
    
    F --> J[XYExtension]
    
    subgraph Server
        A
        D
        E
        G
        H
    end
    
    subgraph Tool
        C
    end
    
    subgraph Basic
        F
        J
    end
    
    subgraph Third
        I
    end
    
    style A fill:#FFA07A,stroke:#333
    style B fill:#FFA07A,stroke:#333
    style C fill:#87CEEB,stroke:#333
    style D fill:#FFA07A,stroke:#333
    style E fill:#FFA07A,stroke:#333
    style F fill:#DDA0DD,stroke:#333
    style G fill:#FFA07A,stroke:#333
    style H fill:#FFA07A,stroke:#333
    style I fill:#F0E68C,stroke:#333
    style J fill:#DDA0DD,stroke:#333
```

## 功能特点

- 提供稳定的基础服务功能
- 高内聚低耦合的设计
- 统一的接口封装，便于使用和维护

## 使用说明

Server 组件为 Business 组件提供基础服务支持，通常不直接在应用程序中使用。

## 安装

各个组件可通过 CocoaPods 单独安装：

```ruby
pod 'XYCoreBluetooth'
pod 'XYLog'
pod 'XYNetwork'
pod 'XYStorage'
pod 'XYWatchConnectivity'
```