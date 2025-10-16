//
//  JSON.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation

public extension Dictionary {
    /// 字典 转 JSON data
    func toJSONData(prettify: Bool = false) -> Data? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }
        let options = (prettify == true) ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization
            .WritingOptions()
        return try? JSONSerialization.data(withJSONObject: self, options: options)
    }

    /// 字典 转 JSON string
    func toJSONString(prettify: Bool = false) -> String? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        let options = (prettify == true) ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization
            .WritingOptions()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: options) else { return nil }
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

