//
//  XYGluDataValue.swift
//  XYGlucose
//
//  Created by hsf on 2026/3/28.
//

import Foundation

// MARK: - XYGluData.Value
/// 血糖值
extension XYGluData {
    public struct Value {
        public let mg: Double
        public let mmol: Double
        
        public init(mg: Double) {
            self.mg = mg
            self.mmol = mg / 18.0
        }
        
        public init(mmol: Double) {
            self.mg = mmol * 18.0
            self.mmol = mmol
        }
    }
}

// MARK: - Double
public extension Double {
    var mg: XYGluData.Value { XYGluData.Value(mg: self) }
    var mmol: XYGluData.Value { XYGluData.Value(mmol: self) }
}

