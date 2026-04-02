# Tool Components

[![License](https://img.shields.io/github/license/hsf89757/XYLib.svg?style=flat)](https://github.com/hsf89757/XYLib/blob/main/LICENSE)

## 目录

<details>
<summary>点击展开目录</summary>

- [Tool Components](#tool-components)
  - [目录](#目录)
  - [简介](#简介)
  - [组件列表](#组件列表)
    - [XYNode](#xynode)
    - [XYUtil](#xyutil)
    - [XYCmd](#xycmd)
  - [架构](#架构)
  - [依赖关系](#依赖关系)
  - [功能特点](#功能特点)
  - [使用说明](#使用说明)
  - [安装](#安装)
  - [要求](#要求)
  - [许可证](#许可证)

</details>

## 简介

Tool 组件是 XYLib 的通用工具组件集合，旨在提供可复用的基础功能模块，支持 iOS/macOS 开发中的常见需求。该组件集成了节点操作、通用工具方法和工作流管理等功能，帮助开发者更高效地构建应用程序。

主要功能包括：
- 节点操作能力（XYNode）
- 常用工具方法（XYUtil）
- 工作流或状态机管理（XYCmd）

## 组件列表

### XYNode

节点操作工具模块，提供创建、管理和遍历树形数据结构的功能。

主要特性：
- 基础树节点操作：创建、添加、删除、查找节点
- 层级管理：自动维护节点层级信息和深度
- 标识符和标签系统：支持通过标识符快速查找节点，通过标签分组管理
- 缓存优化：内置缓存机制提升查找性能
- 可扩展节点：支持展开/收起状态管理，适用于 UI 场景

### XYUtil

常用工具类集合，封装了开发中常用的工具方法。

主要特性：
- 应用信息获取（Bundle ID、名称、版本等）
- 线程安全属性包装器
- 原子操作类（计数器、布尔标志等）
- 状态管理与观察者模式

### XYCmd

工作流或状态机管理模块，用于构建和执行复杂的工作流。

主要特性：
- 命令模式：所有工作单元都遵循统一的命令协议
- 基础命令：提供超时、状态管理、重试等通用功能
- 可执行命令：支持通过闭包快速创建可执行命令
- 分组执行：支持多个命令的串行或并行执行
- 状态管理：内置状态机，跟踪命令执行状态
- 错误处理：完善的错误类型系统

## 架构

Tool 组件采用模块化设计，主要包括以下三个核心模块：

``mermaid
graph TD
    A[Tool 组件] --> B[XYNode]
    A --> C[XYUtil]
    A --> D[XYCmd]
    
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

架构特点：
- 模块解耦，支持按需引入
- 分层架构设计，基础工具（Basic）、日志服务（Server）、第三方库封装（Third）
- 组件化设计，便于维护和扩展

## 依赖关系

Tool 组件内部各模块的依赖关系：

``mermaid
graph TD
    A[XYCmd] --> B[XYLog]
    
    C[XYLog] --> D[XYUtil]
    C --> E[CocoaLumberjack]
    
    D --> F[XYExtension]
    
    subgraph Tool
        A
        D
    end
    
    subgraph Server
        B
        C
    end
    
    subgraph Basic
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

依赖说明：
- `XYCmd` 依赖 `XYLog` 记录执行流程
- `XYLog` 依赖 `XYUtil` 提供基础工具支持，并使用 `CocoaLumberjack` 作为底层日志框架
- `XYUtil` 依赖 `XYExtension` 提供扩展能力

## 功能特点

- 提供通用工具功能
- 支持复杂流程控制
- 可复用的工具模块
- 模块解耦，支持按需引入
- 基于 CocoaPods 的组件化分发
- 支持 Swift 和 Objective-C 混编环境

## 使用说明

Tool 组件提供通用的工具功能，可在各种场景中复用：

1. 使用 XYNode 处理树形数据结构
2. 使用 XYUtil 简化常见的开发任务
3. 使用 XYCmd 管理复杂的工作流和状态转换

## 安装

各个组件可通过 [CocoaPods](https://cocoapods.org) 单独安装：

``ruby
pod 'XYNode'
pod 'XYUtil'
pod 'XYCmd'
```

也可选择性安装需要的组件：

``ruby
# 只安装需要的组件
pod 'XYUtil'      # 如果只需要通用工具
pod 'XYNode'      # 如果只需要节点操作功能
pod 'XYCmd'  # 如果只需要工作流管理功能
```

## 要求

| 平台 | 最低版本 |
|------|----------|
| iOS | 14.0+ |
| watchOS | 9.0+ |

构建工具：
- Xcode 13.0+
- CocoaPods 1.10+

开发环境：
1. 安装 CocoaPods：`gem install cocoapods`
2. 进入各模块 Example 目录（如 `XYNode/Example`）
3. 执行 `pod install` 安装依赖
4. 打开生成的 `.xcworkspace` 文件进行开发

## 许可证

Tool Components 基于 MIT 许可证发布。有关详细信息，请参见 LICENSE 文件。
