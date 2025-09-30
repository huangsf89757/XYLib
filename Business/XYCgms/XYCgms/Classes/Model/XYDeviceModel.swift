//
//  XYDeviceModel.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
//

import Foundation
import CoreBluetooth

public final class XYDeviceModel {
    // MARK: var
    public internal(set) var identifier: String?
    public internal(set) var name: String?
    public internal(set) var sn: String?
    
    /// 关联的peripheral
    public internal(set) var peripheral: CBPeripheral?
    
}
