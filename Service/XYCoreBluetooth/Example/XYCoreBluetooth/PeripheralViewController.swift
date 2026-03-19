//
//  PeripheralViewController.swift
//  XYCoreBluetooth
//
//  Created by hsf89757 on 09/10/2025.
//  Copyright (c) 2025 hsf89757. All rights reserved.
//

import UIKit
import CoreBluetooth
import XYCoreBluetooth

// MARK: - PeripheralViewController
/// 外围侧模式视图控制器，支持自定义服务、特征、广播和通知
class PeripheralViewController: UIViewController {
    
    // MARK: - Properties
    
    // UI元素
    private let statusLabel = UILabel()
    private let startAdvertisingButton = UIButton(type: .system)
    private let stopAdvertisingButton = UIButton(type: .system)
    private let updateValueButton = UIButton(type: .system)
    private let valueTextField = UITextField()
    private let connectedDeviceLabel = UILabel()
    private let logTextView = UITextView()
    
    // 蓝牙相关属性
    private var peripheralManager: XYPeripheralManager!
    
    // 自定义服务和特征UUID
    private let customServiceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")
    private let readCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789013")
    private let writeCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789014")
    private let notifyCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789015")
    
    // 服务和特征对象
    private var customService: CBMutableService?
    private var readCharacteristic: CBMutableCharacteristic?
    private var writeCharacteristic: CBMutableCharacteristic?
    private var notifyCharacteristic: CBMutableCharacteristic?
    
    // 连接状态
    private var isConnected = false
    private var subscribedCentrals: [CBCentral] = []
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPeripheralManager()
    }
    
    // MARK: - Setup
    
    /// 设置用户界面元素
    private func setupUI() {
        // 设置视图背景色
        view.backgroundColor = .white
        
        // 配置状态标签
        statusLabel.text = "蓝牙状态: 未知"
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置开始广播按钮
        startAdvertisingButton.setTitle("开始广播", for: .normal)
        startAdvertisingButton.addTarget(self, action: #selector(startAdvertisingTapped), for: .touchUpInside)
        startAdvertisingButton.isEnabled = false
        startAdvertisingButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置停止广播按钮
        stopAdvertisingButton.setTitle("停止广播", for: .normal)
        stopAdvertisingButton.addTarget(self, action: #selector(stopAdvertisingTapped), for: .touchUpInside)
        stopAdvertisingButton.isEnabled = false
        stopAdvertisingButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置更新值按钮
        updateValueButton.setTitle("更新通知值", for: .normal)
        updateValueButton.addTarget(self, action: #selector(updateValueTapped), for: .touchUpInside)
        updateValueButton.isEnabled = false
        updateValueButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置文本输入框
        valueTextField.placeholder = "输入要发送的值"
        valueTextField.borderStyle = .roundedRect
        valueTextField.text = "Hello from Peripheral"
        valueTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置连接设备标签
        connectedDeviceLabel.text = "连接状态: 无设备连接"
        connectedDeviceLabel.textAlignment = .center
        connectedDeviceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置日志文本视图
        logTextView.text = "日志:\n"
        logTextView.isEditable = false
        logTextView.layer.borderWidth = 1
        logTextView.layer.borderColor = UIColor.lightGray.cgColor
        logTextView.layer.cornerRadius = 8
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加UI元素到视图
        let topStack = UIStackView(arrangedSubviews: [statusLabel, connectedDeviceLabel])
        topStack.axis = .vertical
        topStack.spacing = 8
        topStack.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStack = UIStackView(arrangedSubviews: [startAdvertisingButton, stopAdvertisingButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        let notifyStack = UIStackView(arrangedSubviews: [valueTextField, updateValueButton])
        notifyStack.axis = .horizontal
        notifyStack.spacing = 16
        notifyStack.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [topStack, buttonStack, notifyStack, logTextView])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            updateValueButton.heightAnchor.constraint(equalToConstant: 44),
            notifyStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    /// 初始化并配置XYPeripheralManager
    private func setupPeripheralManager() {
        // 初始化XYPeripheralManager
        peripheralManager = XYPeripheralManager(delegate: self, queue: nil)
    }
    
    /// 创建自定义服务和特征
    private func createCustomServices() {
        // 创建读取特征（可读）
        readCharacteristic = CBMutableCharacteristic(
            type: readCharacteristicUUID,
            properties: [.read],
            value: "Read characteristic value".data(using: .utf8),
            permissions: [.readable]
        )
        
        // 创建写入特征（可写，带响应）
        writeCharacteristic = CBMutableCharacteristic(
            type: writeCharacteristicUUID,
            properties: [.write],
            value: nil,
            permissions: [.writeable]
        )
        
        // 创建通知特征（可读，支持通知）
        notifyCharacteristic = CBMutableCharacteristic(
            type: notifyCharacteristicUUID,
            properties: [.read, .notify],
            value: "Notify characteristic value".data(using: .utf8),
            permissions: [.readable]
        )
        
        // 创建服务并添加特征
        customService = CBMutableService(type: customServiceUUID, primary: true)
        customService?.characteristics = [readCharacteristic!, writeCharacteristic!, notifyCharacteristic!]
        
        // 将服务添加到外设管理器
        if let service = customService {
            peripheralManager.add(service)
        }
        
        addLog("已创建自定义服务和特征")
    }
    
    // MARK: - Actions
    
    /// 开始广播按钮点击事件
    @objc private func startAdvertisingTapped() {
        guard peripheralManager.state == .poweredOn else {
            addLog("蓝牙未开启，无法开始广播")
            return
        }
        
        // 广播数据
        let advertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: "XYCoreBluetooth Demo",
            CBAdvertisementDataServiceUUIDsKey: [customServiceUUID]
        ]
        
        // 开始广播
        peripheralManager.startAdvertising(advertisementData)
        addLog("开始广播成功")
        statusLabel.text = "状态: 正在广播"
        startAdvertisingButton.isEnabled = false
        stopAdvertisingButton.isEnabled = true
    }
    
    /// 停止广播按钮点击事件
    @objc private func stopAdvertisingTapped() {
        peripheralManager.stopAdvertising()
        addLog("已停止广播")
        statusLabel.text = "状态: 已停止广播"
        startAdvertisingButton.isEnabled = true
        stopAdvertisingButton.isEnabled = false
    }
    
    /// 更新通知值按钮点击事件
    @objc private func updateValueTapped() {
        guard let notifyCharacteristic = notifyCharacteristic, let text = valueTextField.text, !text.isEmpty else {
            addLog("请输入要发送的值")
            return
        }
        
        // 将文本转换为数据
        guard let data = text.data(using: .utf8) else {
            addLog("数据转换失败")
            return
        }
        
        // 更新特征值并发送通知给订阅的中央设备
        if subscribedCentrals.isEmpty {
            addLog("没有订阅的中央设备")
            return
        }
        
        let success = peripheralManager?.updateValue(data, for: notifyCharacteristic, onSubscribedCentrals: subscribedCentrals)
        
        if success ?? false {
            addLog("已发送通知: \(text)")
        } else {
            addLog("发送通知失败")
        }
    }
    
    // MARK: - Helper Methods
    
    /// 添加日志
    private func addLog(_ message: String) {
        print(message)
        
        DispatchQueue.main.async {
            let timestamp = self.getCurrentTimestamp()
            self.logTextView.text.append("\(timestamp) - \(message)\n")
            
            // 滚动到底部
            let bottomRange = NSRange(location: self.logTextView.text.count - 1, length: 1)
            self.logTextView.scrollRangeToVisible(bottomRange)
        }
    }
    
    /// 获取当前时间戳
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    /// 更新连接状态UI
    private func updateConnectionStatus() {
        DispatchQueue.main.async {
            if self.isConnected {
                self.connectedDeviceLabel.text = "连接状态: 已连接 (\(self.subscribedCentrals.count) 个订阅)"
                self.updateValueButton.isEnabled = !self.subscribedCentrals.isEmpty
            } else {
                self.connectedDeviceLabel.text = "连接状态: 无设备连接"
                self.updateValueButton.isEnabled = false
            }
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension PeripheralViewController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            statusLabel.text = "蓝牙状态: 已开启"
            addLog("蓝牙已开启")
            startAdvertisingButton.isEnabled = true
            
            // 蓝牙已开启，创建服务和特征
            createCustomServices()
            
        case .poweredOff:
            statusLabel.text = "蓝牙状态: 已关闭"
            addLog("蓝牙已关闭")
            startAdvertisingButton.isEnabled = false
            stopAdvertisingButton.isEnabled = false
            updateValueButton.isEnabled = false
            
        case .unauthorized:
            statusLabel.text = "蓝牙状态: 未授权"
            addLog("蓝牙未授权")
            startAdvertisingButton.isEnabled = false
            
        case .unsupported:
            statusLabel.text = "蓝牙状态: 不支持"
            addLog("设备不支持蓝牙LE")
            startAdvertisingButton.isEnabled = false
            
        case .unknown:
            statusLabel.text = "蓝牙状态: 未知"
            addLog("蓝牙状态未知")
            
        case .resetting:
            statusLabel.text = "蓝牙状态: 重置中"
            addLog("蓝牙正在重置")
            startAdvertisingButton.isEnabled = false
            stopAdvertisingButton.isEnabled = false
            updateValueButton.isEnabled = false
            
        @unknown default:
            statusLabel.text = "蓝牙状态: 未知"
            addLog("未知蓝牙状态")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            addLog("广播启动失败: \(error.localizedDescription)")
            statusLabel.text = "状态: 广播失败"
            startAdvertisingButton.isEnabled = true
            stopAdvertisingButton.isEnabled = false
        } else {
            addLog("广播已成功启动")
            statusLabel.text = "状态: 正在广播"
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        addLog("收到读取请求")
        
        // 检查请求的特征
        if request.characteristic.uuid == readCharacteristicUUID {
            // 响应读取请求
            if let value = readCharacteristic?.value {
                if request.offset > value.count {
                    peripheral.respond(to: request, withResult: .invalidOffset)
                } else {
                    let range = Range(uncheckedBounds: (lower: request.offset, upper: value.count))
                    request.value = value.subdata(in: range)
                    peripheral.respond(to: request, withResult: .success)
                    addLog("已响应读取请求")
                }
            } else {
                peripheral.respond(to: request, withResult: .attributeNotFound)
            }
        } else if request.characteristic.uuid == notifyCharacteristicUUID {
            // 响应通知特征的读取请求
            if let value = notifyCharacteristic?.value {
                if request.offset > value.count {
                    peripheral.respond(to: request, withResult: .invalidOffset)
                } else {
                    let range = Range(uncheckedBounds: (lower: request.offset, upper: value.count))
                    request.value = value.subdata(in: range)
                    peripheral.respond(to: request, withResult: .success)
                    addLog("已响应通知特征读取请求")
                }
            } else {
                peripheral.respond(to: request, withResult: .attributeNotFound)
            }
        } else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        addLog("收到写入请求")
        
        // 处理所有写入请求
        for request in requests {
            if request.characteristic.uuid == writeCharacteristicUUID {
                // 保存写入的值
                writeCharacteristic?.value = request.value
                
                // 尝试将数据转换为字符串并显示
                if let value = request.value, let stringValue = String(data: value, encoding: .utf8) {
                    addLog("收到写入数据: \(stringValue)")
                    
                    // 显示接收到的值
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "收到写入数据", message: stringValue, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "确定", style: .default))
                        self.present(alert, animated: true)
                    }
                }
                
                // 响应写入请求
                peripheral.respond(to: request, withResult: .success)
            } else {
                peripheral.respond(to: request, withResult: .attributeNotFound)
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        addLog("中央设备订阅了特征: \(characteristic.uuid.uuidString)")
        
        // 添加到订阅列表
        if !subscribedCentrals.contains(central) {
            subscribedCentrals.append(central)
        }
        
        isConnected = true
        updateConnectionStatus()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        addLog("中央设备取消订阅了特征: \(characteristic.uuid.uuidString)")
        
        // 从订阅列表中移除
        if let index = subscribedCentrals.firstIndex(where: { $0.identifier == central.identifier }) {
            subscribedCentrals.remove(at: index)
        }
        
        // 如果没有订阅的中央设备，更新连接状态
        if subscribedCentrals.isEmpty {
            isConnected = false
        }
        updateConnectionStatus()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            addLog("添加服务失败: \(error.localizedDescription)")
        } else {
            addLog("服务添加成功: \(service.uuid.uuidString)")
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        addLog("准备好更新订阅者")
        
        // 可以在这里重试之前失败的通知
        if let notifyCharacteristic = notifyCharacteristic, let text = valueTextField.text, !text.isEmpty, let data = text.data(using: .utf8), !subscribedCentrals.isEmpty {
            peripheral.updateValue(data, for: notifyCharacteristic, onSubscribedCentrals: subscribedCentrals)
            addLog("重试发送通知: \(text)")
        }
    }
}

// MARK: - XYPeripheralManagerDelegate
extension PeripheralViewController: XYPeripheralManagerDelegate {
    
    func peripheralManager(_ peripheral: CBPeripheralManager, startAdvertising advertisementData: [String: Any]?) {
        addLog("XYPeripheralManager: 开始广播")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, stopAdvertising: Void) {
        addLog("XYPeripheralManager: 停止广播")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, add service: CBMutableService) {
        addLog("XYPeripheralManager: 添加服务")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, remove service: CBMutableService) {
        addLog("XYPeripheralManager: 移除服务")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, removeAllServices: Void) {
        addLog("XYPeripheralManager: 移除所有服务")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, setDescriptors descriptors: [CBDescriptor]?, forCharacteristic characteristic: CBMutableCharacteristic) {
        addLog("XYPeripheralManager: 设置描述符")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, updateValue value: Data, for characteristic: CBCharacteristic, onSubscribedCentrals centrals: [CBCentral]) -> Bool {
        addLog("XYPeripheralManager: 更新特征值")
        return true
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, respondTo request: CBATTRequest, withResult result: CBATTError.Code) {
        addLog("XYPeripheralManager: 响应请求")
    }
    
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, publishL2CAPChannelWithEncryption encryptionRequired: Bool) {
        addLog("XYPeripheralManager: 发布L2CAPChannel")
    }
    
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, unpublishL2CAPChannel PSM: CBL2CAPPSM) {
        addLog("XYPeripheralManager: 取消L2CAPChannel")
    }
}
