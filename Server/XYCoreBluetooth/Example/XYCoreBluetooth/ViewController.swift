//
//  ViewController.swift
//  XYCoreBluetooth
//
//  Created by hsf89757 on 09/10/2025.
//  Copyright (c) 2025 hsf89757. All rights reserved.
//

import UIKit
import CoreBluetooth
import XYCoreBluetooth

// MARK: - ViewController
class ViewController: UIViewController {
    
    // MARK: - Properties
    
    // UI元素
    private let statusLabel = UILabel()
    private let scanButton = UIButton(type: .system)
    private let stopScanButton = UIButton(type: .system)
    private let tableView = UITableView()
    
    // 蓝牙相关属性
    private var centralManager: XYCentralManager?
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    
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
        
        // 设置标题
        title = "蓝牙设备扫描"
        
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
        
        // 配置表格视图
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加UI元素到视图
        let buttonStack = UIStackView(arrangedSubviews: [scanButton, stopScanButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [statusLabel, buttonStack, tableView])
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
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
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
        discoveredPeripherals.removeAll()
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let peripheral = discoveredPeripherals[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = peripheral.name ?? "未知设备"
        content.secondaryText = peripheral.identifier.uuidString
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 停止扫描
        centralManager?.stopScan()
        stopScanTapped()
        
        // 连接选中的设备
        let peripheral = discoveredPeripherals[indexPath.row]
        print("尝试连接设备: \(peripheral.name ?? "未知设备")")
        statusLabel.text = "正在连接: \(peripheral.name ?? "未知设备")"
        
        centralManager?.connect(peripheral, options: nil)
    }
}

// MARK: - CBCentralManagerDelegate
extension ViewController: CBCentralManagerDelegate {
    
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
        
        // 这里可以开始发现设备的服务
        peripheral.delegate = self as? CBPeripheralDelegate
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
        }
        statusLabel.text = "设备已断开连接"
        
        // 可以选择重新开始扫描
        scanButton.isEnabled = true
    }
}

// MARK: - XYCentralManagerDelegate
extension ViewController: XYCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, scanForPeripheralsWithServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        print("XYCentralManager: 开始扫描设备")
    }
    
    func centralManager(_ central: CBCentralManager, stopScan: Void) {
        print("XYCentralManager: 停止扫描设备")
    }
    
    func centralManager(_ central: CBCentralManager, connect peripheral: CBPeripheral, options: [String: Any]?) {
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
    func centralManager(_ central: CBCentralManager, registerForConnectionEventsWithOptions options: [CBConnectionEventMatchingOption: Any]?) {
        print("XYCentralManager: 注册连接事件")
    }
}

