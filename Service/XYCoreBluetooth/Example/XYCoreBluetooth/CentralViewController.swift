//
//  CentralViewController.swift
//  XYCoreBluetooth
//
//  Created by hsf89757 on 09/10/2025.
//  Copyright (c) 2025 hsf89757. All rights reserved.
//

import UIKit
import CoreBluetooth
import XYCoreBluetooth

// MARK: - CentralViewController
/// 中央侧模式视图控制器，支持扫描、连接、读写蓝牙设备
class CentralViewController: UIViewController {
    
    // MARK: - Properties
    
    // UI元素
    private let statusLabel = UILabel()
    private let scanButton = UIButton(type: .system)
    private let stopScanButton = UIButton(type: .system)
    private let disconnectButton = UIButton(type: .system)
    private let tableView = UITableView()
    private let characteristicInfoView = UIView()
    private let serviceLabel = UILabel()
    private let characteristicLabel = UILabel()
    private let readButton = UIButton(type: .system)
    private let writeButton = UIButton(type: .system)
    private let valueTextField = UITextField()
    
    // 蓝牙相关属性
    private var centralManager: XYCentralManager?
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    private var discoveredServices: [CBService] = []
    private var discoveredCharacteristics: [CBCharacteristic] = []
    private var selectedCharacteristic: CBCharacteristic?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCentralManager()
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
        
        // 配置扫描按钮
        scanButton.setTitle("开始扫描", for: .normal)
        scanButton.addTarget(self, action: #selector(startScanTapped), for: .touchUpInside)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置停止扫描按钮
        stopScanButton.setTitle("停止扫描", for: .normal)
        stopScanButton.addTarget(self, action: #selector(stopScanTapped), for: .touchUpInside)
        stopScanButton.isEnabled = false
        stopScanButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置断开连接按钮
        disconnectButton.setTitle("断开连接", for: .normal)
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        disconnectButton.isEnabled = false
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置表格视图
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置特征信息视图
        characteristicInfoView.backgroundColor = .systemGroupedBackground
        characteristicInfoView.layer.cornerRadius = 8
        characteristicInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置服务标签
        serviceLabel.text = "服务: 未选择"
        serviceLabel.textAlignment = .left
        serviceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置特征标签
        characteristicLabel.text = "特征: 未选择"
        characteristicLabel.textAlignment = .left
        characteristicLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置读取按钮
        readButton.setTitle("读取特征", for: .normal)
        readButton.addTarget(self, action: #selector(readCharacteristicTapped), for: .touchUpInside)
        readButton.isEnabled = false
        readButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置写入按钮
        writeButton.setTitle("写入特征", for: .normal)
        writeButton.addTarget(self, action: #selector(writeCharacteristicTapped), for: .touchUpInside)
        writeButton.isEnabled = false
        writeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置文本输入框
        valueTextField.placeholder = "输入要写入的值"
        valueTextField.borderStyle = .roundedRect
        valueTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 将元素添加到特征信息视图
        let infoStackView = UIStackView(arrangedSubviews: [serviceLabel, characteristicLabel])
        infoStackView.axis = .vertical
        infoStackView.spacing = 8
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStackView = UIStackView(arrangedSubviews: [readButton, writeButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 16
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        characteristicInfoView.addSubview(infoStackView)
        characteristicInfoView.addSubview(valueTextField)
        characteristicInfoView.addSubview(buttonStackView)
        
        // 添加UI元素到主视图
        let buttonStack = UIStackView(arrangedSubviews: [scanButton, stopScanButton, disconnectButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [statusLabel, buttonStack, tableView, characteristicInfoView])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 主堆栈视图约束
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            // 按钮堆栈约束
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            
            // 特征信息视图内部约束
            infoStackView.topAnchor.constraint(equalTo: characteristicInfoView.topAnchor, constant: 16),
            infoStackView.leadingAnchor.constraint(equalTo: characteristicInfoView.leadingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: characteristicInfoView.trailingAnchor, constant: -16),
            
            valueTextField.topAnchor.constraint(equalTo: infoStackView.bottomAnchor, constant: 16),
            valueTextField.leadingAnchor.constraint(equalTo: characteristicInfoView.leadingAnchor, constant: 16),
            valueTextField.trailingAnchor.constraint(equalTo: characteristicInfoView.trailingAnchor, constant: -16),
            
            buttonStackView.topAnchor.constraint(equalTo: valueTextField.bottomAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: characteristicInfoView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: characteristicInfoView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: characteristicInfoView.bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44),
            
            // 特征信息视图高度约束
            characteristicInfoView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    /// 初始化并配置XYCentralManager
    private func setupCentralManager() {
        // 初始化XYCentralManager
        centralManager = XYCentralManager(delegate: self)
    }
    
    // MARK: - Actions
    
    /// 开始扫描按钮点击事件
    @objc private func startScanTapped() {
        print("开始扫描蓝牙设备")
        statusLabel.text = "正在扫描..."
        scanButton.isEnabled = false
        stopScanButton.isEnabled = true
        disconnectButton.isEnabled = false
        discoveredPeripherals.removeAll()
        discoveredServices.removeAll()
        discoveredCharacteristics.removeAll()
        selectedCharacteristic = nil
        serviceLabel.text = "服务: 未选择"
        characteristicLabel.text = "特征: 未选择"
        readButton.isEnabled = false
        writeButton.isEnabled = false
        tableView.reloadData()
        
        // 开始扫描设备，不指定特定服务
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    /// 停止扫描按钮点击事件
    @objc private func stopScanTapped() {
        print("停止扫描蓝牙设备")
        statusLabel.text = "扫描已停止"
        scanButton.isEnabled = true
        stopScanButton.isEnabled = false
        
        // 停止扫描
        centralManager?.stopScan()
    }
    
    /// 断开连接按钮点击事件
    @objc private func disconnectTapped() {
        guard let peripheral = connectedPeripheral else { return }
        
        print("断开连接设备: \(peripheral.name ?? "未知设备")")
        statusLabel.text = "正在断开连接"
        disconnectButton.isEnabled = false
        
        // 断开连接
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    /// 读取特征按钮点击事件
    @objc private func readCharacteristicTapped() {
        guard let peripheral = connectedPeripheral, let characteristic = selectedCharacteristic else { return }
        
        print("读取特征值")
        peripheral.readValue(for: characteristic)
    }
    
    /// 写入特征按钮点击事件
    @objc private func writeCharacteristicTapped() {
        guard let peripheral = connectedPeripheral, let characteristic = selectedCharacteristic, let text = valueTextField.text, !text.isEmpty else { return }
        
        // 将文本转换为数据
        if let data = text.data(using: .utf8) {
            print("写入特征值: \(text)")
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 更新特征列表
    private func updateCharacteristicsUI() {
        if let characteristic = selectedCharacteristic {
            let serviceUUID = characteristic.service?.uuid.uuidString ?? "nil"
            let characteristicUUID = characteristic.uuid.uuidString
            serviceLabel.text = "服务: \(serviceUUID)"
            characteristicLabel.text = "特征: \(characteristicUUID)"
            
            // 检查特征的属性，启用相应的按钮
            let canRead = characteristic.properties.contains(.read)
            let canWrite = characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
            
            readButton.isEnabled = canRead
            writeButton.isEnabled = canWrite
        } else {
            serviceLabel.text = "特征: 未选择"
            characteristicLabel.text = "特征值: 未选择"
            readButton.isEnabled = false
            writeButton.isEnabled = false
        }
    }
    
    // 显示特征选择弹窗
    private func showCharacteristicSelectionAlert() {
        let alert = UIAlertController(title: "选择特征", message: "请选择要操作的特征", preferredStyle: .actionSheet)
        
        // 添加取消按钮
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 添加特征选项
        for characteristic in discoveredCharacteristics {
            let serviceUUID = characteristic.service?.uuid.uuidString ?? "nil"
            let characteristicUUID = characteristic.uuid.uuidString
            let actionTitle = "特征: \(characteristicUUID)\n服务: \(serviceUUID)"
            
            let action = UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
                self?.selectedCharacteristic = characteristic
                self?.updateCharacteristicsUI()
            }
            alert.addAction(action)
        }
        
        // 在iPad上显示为弹窗
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension CentralViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if connectedPeripheral != nil {
            // 如果已连接，显示特征列表
            return discoveredCharacteristics.count > 0 ? discoveredCharacteristics.count : 1
        } else {
            // 否则显示发现的设备列表
            return discoveredPeripherals.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if let peripheral = connectedPeripheral {
            // 显示特征信息
            if discoveredCharacteristics.count > 0 {
                let characteristic = discoveredCharacteristics[indexPath.row]
                let properties = getCharacteristicPropertiesDescription(characteristic)
                
                var content = cell.defaultContentConfiguration()
                content.text = "特征: \(characteristic.uuid.uuidString)"
                content.secondaryText = "服务: \(characteristic.service?.uuid.uuidString ?? "nil")\n属性: \(properties)"
                cell.contentConfiguration = content
            } else {
                var content = cell.defaultContentConfiguration()
                content.text = "未发现特征"
                content.textProperties.color = .secondaryLabel
                cell.contentConfiguration = content
            }
        } else {
            // 显示设备信息
            let peripheral = discoveredPeripherals[indexPath.row]
            
            var content = cell.defaultContentConfiguration()
            content.text = peripheral.name ?? "未知设备"
            content.secondaryText = peripheral.identifier.uuidString
            cell.contentConfiguration = content
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if connectedPeripheral == nil {
            // 停止扫描并连接设备
            centralManager?.stopScan()
            stopScanTapped()
            
            let peripheral = discoveredPeripherals[indexPath.row]
            print("尝试连接设备: \(peripheral.name ?? "未知设备")")
            statusLabel.text = "正在连接: \(peripheral.name ?? "未知设备")"
            
            centralManager?.connect(peripheral, options: nil)
        } else if discoveredCharacteristics.count > 0 {
            // 选择特征进行操作
            selectedCharacteristic = discoveredCharacteristics[indexPath.row]
            updateCharacteristicsUI()
        }
    }
    
    // 获取特征属性描述
    private func getCharacteristicPropertiesDescription(_ characteristic: CBCharacteristic) -> String {
        var properties: [String] = []
        
        if characteristic.properties.contains(.read) {
            properties.append("读")
        }
        if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
            properties.append("写")
        }
        if characteristic.properties.contains(.notify) {
            properties.append("通知")
        }
        if characteristic.properties.contains(.indicate) {
            properties.append("指示")
        }
        
        return properties.joined(separator: ", ")
    }
}

// MARK: - CBCentralManagerDelegate
extension CentralViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusLabel.text = "蓝牙状态: 已开启"
            scanButton.isEnabled = true
        case .poweredOff:
            statusLabel.text = "蓝牙状态: 已关闭"
            scanButton.isEnabled = false
        case .unauthorized:
            statusLabel.text = "蓝牙状态: 未授权"
            scanButton.isEnabled = false
        case .unsupported:
            statusLabel.text = "蓝牙状态: 不支持"
            scanButton.isEnabled = false
        case .unknown:
            statusLabel.text = "蓝牙状态: 未知"
            scanButton.isEnabled = false
        case .resetting:
            statusLabel.text = "蓝牙状态: 重置中"
            scanButton.isEnabled = false
        @unknown default:
            statusLabel.text = "蓝牙状态: 未知"
            scanButton.isEnabled = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 避免重复添加相同的设备
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            tableView.reloadData()
            print("发现设备: \(peripheral.name ?? "未知设备") (RSSI: \(RSSI))")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("成功连接设备: \(peripheral.name ?? "未知设备")")
        statusLabel.text = "已连接: \(peripheral.name ?? "未知设备")"
        connectedPeripheral = peripheral
        disconnectButton.isEnabled = true
        
        // 设置外设代理并开始发现服务
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败: \(peripheral.name ?? "未知设备") - \(error?.localizedDescription ?? "未知错误")")
        statusLabel.text = "连接失败: \(error?.localizedDescription ?? "未知错误")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("设备断开连接: \(peripheral.name ?? "未知设备")")
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
            discoveredServices.removeAll()
            discoveredCharacteristics.removeAll()
            selectedCharacteristic = nil
            serviceLabel.text = "服务: 未选择"
            characteristicLabel.text = "特征: 未选择"
            readButton.isEnabled = false
            writeButton.isEnabled = false
        }
        statusLabel.text = "设备已断开连接"
        disconnectButton.isEnabled = false
        tableView.reloadData()
    }
}

// MARK: - CBPeripheralDelegate
extension CentralViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("发现服务失败: \(error.localizedDescription)")
            statusLabel.text = "发现服务失败"
            return
        }
        
        guard let services = peripheral.services else {
            print("未发现服务")
            statusLabel.text = "未发现服务"
            return
        }
        
        print("发现服务数量: \(services.count)")
        discoveredServices = services
        
        // 发现每个服务的特征
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("发现特征失败: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("未发现特征")
            return
        }
        
        print("发现特征数量: \(characteristics.count)")
        
        // 添加特征到列表
        for characteristic in characteristics {
            if !discoveredCharacteristics.contains(where: { $0.uuid.uuidString == characteristic.uuid.uuidString }) {
                discoveredCharacteristics.append(characteristic)
            }
            
            // 如果特征支持通知，启用通知
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        tableView.reloadData()
        statusLabel.text = "已连接: \(peripheral.name ?? "未知设备")"
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("读取特征值失败: \(error.localizedDescription)")
            return
        }
        
        guard let value = characteristic.value else {
            print("特征值为空")
            return
        }
        
        // 尝试将数据转换为字符串
        if let stringValue = String(data: value, encoding: .utf8) {
            print("读取到特征值: \(stringValue)")
            
            // 如果是当前选中的特征，更新UI
            if selectedCharacteristic?.uuid.uuidString == characteristic.uuid.uuidString {
                characteristicLabel.text = "特征: \(characteristic.uuid.uuidString)\n值: \(stringValue)"
            }
            
            // 显示值
            let alert = UIAlertController(title: "读取到特征值", message: stringValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        } else {
            // 显示十六进制数据
            let hexString = value.map { String(format: "%02X", $0) }.joined(separator: " ")
            print("读取到特征值 (十六进制): \(hexString)")
            
            let alert = UIAlertController(title: "读取到特征值 (十六进制)", message: hexString, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("写入特征值失败: \(error.localizedDescription)")
            
            let alert = UIAlertController(title: "写入失败", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        } else {
            print("写入特征值成功")
            
            let alert = UIAlertController(title: "写入成功", message: "数据已成功写入", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("更新通知状态失败: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("已启用特征通知: \(characteristic.uuid.uuidString)")
        } else {
            print("已禁用特征通知: \(characteristic.uuid.uuidString)")
        }
    }
}

// MARK: - XYCentralManagerDelegate
extension CentralViewController: XYCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, scanForPeripheralsWithServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        print("XYCentralManager: 开始扫描设备")
    }
    
    func centralManager(_ central: CBCentralManager, stopScan: Void) {
        print("XYCentralManager: 停止扫描设备")
    }
    
    func centralManager(_ central: CBCentralManager, registerForConnectionEventsWith peripheral: CBPeripheral, options: [String: Any]?) {
        print("XYCentralManager: 连接设备")
    }
    
    func centralManager(_ central: CBCentralManager, cancelPeripheralConnection peripheral: CBPeripheral) {
        print("XYCentralManager: 取消设备连接")
    }
    
    // MARK: - Peripheral retrieval methods
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrievePeripheralsWithIdentifiers identifiers: [UUID], returns peripherals: [CBPeripheral]) {
        print("XYCentralManager: 检索到设备")
    }
    
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrieveConnectedPeripheralsWithServices serviceUUIDs: [CBUUID], returns peripherals: [CBPeripheral]) {
        print("XYCentralManager: 检索到已连接设备")
    }
    
    // MARK: - Connection events
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManager, registerForConnectionEventsWithOptions options: [String: Any]?) {
        print("XYCentralManager: 注册连接事件")
    }
}
