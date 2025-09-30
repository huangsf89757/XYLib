# Tool Components

Tool 组件包含 XYLib 的通用工具模块，提供工作流管理、节点操作等功能。

## 组件列表

### XYNode
节点操作工具模块。

### XYUtil
常用工具类集合（日期、字符串、加密等）。

### XYWorkflow
工作流或状态机管理模块。

## 架构图

```mermaid
graph TD
    A[Tool 组件] --> B[XYNode]
    A --> C[XYUtil]
    A --> D[XYWorkflow]
    
    subgraph Tool
        B
        C
        D
    end
    
    style A fill:#87CEEB,stroke:#333
    style B fill:#E0EEEE,stroke:#333
    style C fill:#E0EEEE,stroke:#333
    style D fill:#E0EEEE,stroke:#333
```

## 依赖关系

Tool 组件内部各模块的依赖关系：

```mermaid
graph TD
    A[XYWorkflow] --> B[XYLog]
    
    C[XYLog] --> D[XYUtil]
    C --> E[CocoaLumberjack]
    
    D --> F[XYExtension]
    
    subgraph Tool
        A
    end
    
    subgraph Server
        B
        C
    end
    
    subgraph Basic
        D
        F
    end
    
    subgraph Third
        E
    end
    
    style A fill:#87CEEB,stroke:#333
    style B fill:#FFA07A,stroke:#333
    style C fill:#FFA07A,stroke:#333
    style D fill:#DDA0DD,stroke:#333
    style E fill:#F0E68C,stroke:#333
    style F fill:#DDA0DD,stroke:#333
```

## 功能特点

- 提供通用工具功能
- 支持复杂流程控制
- 可复用的工具模块

## 使用说明

Tool 组件提供通用的工具功能，可在各种场景中复用。

## 安装

各个组件可通过 CocoaPods 单独安装：

```ruby
pod 'XYNode'
pod 'XYUtil'
pod 'XYWorkflow'
```