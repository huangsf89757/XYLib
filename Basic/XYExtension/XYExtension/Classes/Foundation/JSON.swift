//
//  JSON.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation

public extension Dictionary {
    /// 字典转 JSON Data
    /// - Parameters:
    ///   - prettify: 是否格式化输出
    ///   - sortedKeys: 是否按键排序（iOS 11+ / macOS 10.13+）
    func toJSONData(prettify: Bool = false, sortedKeys: Bool = true) -> Data? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }
        
        var options: JSONSerialization.WritingOptions = []
        if prettify {
            options.insert(.prettyPrinted)
        }
        if sortedKeys {
            options.insert(.sortedKeys)
        }
        
        return try? JSONSerialization.data(withJSONObject: self, options: options)
    }

    /// 字典转 JSON String
    /// - Parameters:
    ///   - prettify: 是否格式化输出
    ///   - sortedKeys: 是否按键排序（iOS 11+ / macOS 10.13+）
    func toJSONString(prettify: Bool = false, sortedKeys: Bool = true) -> String? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        
        var options: JSONSerialization.WritingOptions = []
        if prettify {
            options.insert(.prettyPrinted)
        }
        if sortedKeys {
            options.insert(.sortedKeys)
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: options) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
}

public extension Array {
    /// 数组 转 JSON data
    func toJSONData(prettify: Bool = false) -> Data? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }
        let options = (prettify == true) ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization
            .WritingOptions()
        return try? JSONSerialization.data(withJSONObject: self, options: options)
    }

    /// 数组转 JSON string
    func toJSONString(prettify: Bool = false) -> String? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        let options = (prettify == true) ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization
            .WritingOptions()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: options) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
}


public extension Data {
    /// JSON data 转 JSON
    func toJSONString(encoding: String.Encoding = .utf8) -> String? {
        return String(data: self, encoding: encoding)
    }

    /// JSON data 转 字典
    func toDictionary(options: JSONSerialization.ReadingOptions = []) -> [String: Any]? {
        do {
           if let jsonObject = try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any] {
               return jsonObject
           }
       } catch {
           print("JSON data 转 字典 失败 \(error)")
       }
       return nil
    }
}

public extension String {
    /// JSON string 转 JSON data
    func toJSONData(encoding: String.Encoding = .utf8) -> Data? {
        if let data = self.data(using: encoding) {
            return data
        }
        return nil
    }

    /// JSON string 转 字典
    func toDictionary(options: JSONSerialization.ReadingOptions = []) -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: options) as? [String: Any] {
                    return jsonObject
                }
            } catch {
                print("JSON string 转 字典 失败 \(error)")
            }
        }
        return nil
    }
}

