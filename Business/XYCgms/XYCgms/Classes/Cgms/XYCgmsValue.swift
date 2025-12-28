//
//  XYCgmsValue.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

// MARK: - Import
// System
import Foundation
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYCgmsValue
/// 血糖值
/// 1 mg/dL = 18 mmol/L
public struct XYCgmsValue {
    let mg: Double
    let mmol: Double
    
    init(mg: Double) {
        self.mg = mg
        self.mmol = mg / 18.0
    }
    
    init(mmol: Double) {
        self.mg = mmol * 18.0
        self.mmol = mmol
    }
}


