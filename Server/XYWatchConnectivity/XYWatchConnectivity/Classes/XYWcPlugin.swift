//
//  XYWcPlugin.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import WatchConnectivity

public protocol XYWcPlugin: WCSessionDelegate {
    func sessionDidTryActivate(_ session: WCSession)
    func session(_ session: WCSession, didTryUpdateApplicationContext dict: [String : Any])
    func session(_ session: WCSession, didTrySendMessage dict: [String : Any], replyHandler: (([String : Any]) -> Void)?)
    func session(_ session: WCSession, didTrySendMessage data: Data, replyHandler: ((Data) -> Void)?)
    
    @available(iOS 14.0, *)
    func session(_ session: WCSession, didTryTransferCurrentComplicationUserInfo dict: [String : Any])
    
    func session(_ session: WCSession, didTryTransferUserInfo dict: [String : Any])
    func session(_ session: WCSession, didTryTransferFileAt url: URL, metadata: [String: Any]?)
}

public extension XYWcPlugin {
    func sessionDidTryActivate(_ session: WCSession) {}
    func session(_ session: WCSession, didTryUpdateApplicationContext dict: [String : Any]) {}
    func session(_ session: WCSession, didTrySendMessage dict: [String : Any], replyHandler: (([String : Any]) -> Void)?) {}
    func session(_ session: WCSession, didTrySendMessage data: Data, replyHandler: ((Data) -> Void)?) {}
    func session(_ session: WCSession, didTryTransferCurrentComplicationUserInfo dict: [String : Any]) {}
    func session(_ session: WCSession, didTryTransferUserInfo dict: [String : Any]) {}
    func session(_ session: WCSession, didTryTransferFileAt url: URL, metadata: [String: Any]?) {}
}
