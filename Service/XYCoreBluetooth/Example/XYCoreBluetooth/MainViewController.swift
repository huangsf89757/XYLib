//
//  MainViewController.swift
//  XYCoreBluetooth
//
//  Created by hsf89757 on 09/10/2025.
//  Copyright (c) 2025 hsf89757. All rights reserved.
//

import UIKit

// MARK: - MainViewController
/// 应用入口页面，用于选择使用中央侧或外围侧Demo
class MainViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 中央侧模式按钮
    private let centralModeButton = UIButton(type: .system)
    
    /// 外围侧模式按钮
    private let peripheralModeButton = UIButton(type: .system)
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    /// 设置用户界面元素
    private func setupUI() {
        // 设置视图背景色
        view.backgroundColor = .white
        
        // 设置标题
        title = "蓝牙Demo选择"
        
        // 配置中央侧模式按钮
        centralModeButton.setTitle("中央侧模式", for: .normal)
        centralModeButton.setTitleColor(.white, for: .normal)
        centralModeButton.backgroundColor = .systemBlue
        centralModeButton.layer.cornerRadius = 8
        centralModeButton.addTarget(self, action: #selector(centralModeTapped), for: .touchUpInside)
        centralModeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置外围侧模式按钮
        peripheralModeButton.setTitle("外围侧模式", for: .normal)
        peripheralModeButton.setTitleColor(.white, for: .normal)
        peripheralModeButton.backgroundColor = .systemGreen
        peripheralModeButton.layer.cornerRadius = 8
        peripheralModeButton.addTarget(self, action: #selector(peripheralModeTapped), for: .touchUpInside)
        peripheralModeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加UI元素到视图
        let stackView = UIStackView(arrangedSubviews: [centralModeButton, peripheralModeButton])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40),
            centralModeButton.heightAnchor.constraint(equalToConstant: 50),
            peripheralModeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    
    /// 中央侧模式按钮点击事件
    @objc private func centralModeTapped() {
        let centralVC = CentralViewController()
        centralVC.title = "中央侧模式"
        navigationController?.pushViewController(centralVC, animated: true)
    }
    
    /// 外围侧模式按钮点击事件
    @objc private func peripheralModeTapped() {
        let peripheralVC = PeripheralViewController()
        peripheralVC.title = "外围侧模式"
        navigationController?.pushViewController(peripheralVC, animated: true)
    }
}
