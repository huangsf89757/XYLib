# Business Components

Business 组件包含 XYLib 的核心业务逻辑实现，通常依赖于 Server 和 Basic 组件。

## 组件列表

### XYCgms
核心业务管理服务模块（可能为 CGMS 连续血糖监测相关），实现具体业务逻辑。

## 架构图

```mermaid
graph TD
    A[Business 组件] --> B[XYCgms]
    
    subgraph Business
        B
    end
    
    style A fill:#98FB98,stroke:#333
    style B fill:#F0FFF0,stroke:#333
```

## 依赖关系

XYCgms 组件依赖于多个下层组件：

```mermaid
graph TD
    A[XYCgms] --> B[XYCoreBluetooth]
    A --> C[XYWatchConnectivity]
    A --> D[XYStorage]
    A --> E[XYNetwork]
    A --> F[XYLog]
    A --> G[MTBleCore]
    
    subgraph Business
        A
    end
    
    subgraph Server
        B
        C
        D
        E
        F
    end
    
    subgraph Third
        G
    end
    
    style A fill:#98FB98,stroke:#333
    style B fill:#FFA07A,stroke:#333
    style C fill:#FFA07A,stroke:#333
    style D fill:#FFA07A,stroke:#333
    style E fill:#FFA07A,stroke:#333
    style F fill:#FFA07A,stroke:#333
    style G fill:#F0E68C,stroke:#333
```

## 功能特点

- 实现核心业务逻辑
- 依赖基础服务组件
- 提供业务相关的 API 接口

## 使用说明

Business 组件实现具体的业务功能，通常在应用程序中直接使用。

## 安装

通过 CocoaPods 安装：

```ruby
pod 'XYCgms'
```