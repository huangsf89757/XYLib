//
//  XYWcManager.swift
//  XYCgms
//
//  Created by hsf on 2025/9/2.
//


import Foundation
import WatchConnectivity
import XYExtension
import XYLog

public final class XYWcManager: NSObject {
    // MARK: shared
    public static let shared = XYWcManager()
    private override init() {}
    
    // MARK: log
#if os(watchOS)
    private static let logTag = "WC.WatchOS"
#elseif os(iOS)
    private static let logTag = "WC.iOS"
#endif
    private static let logTagSender = "Sender"
    private static let logTagReceiver = "Receiver"
    
    // MARK: var
    /// 会话
    public let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    /// 保存文件传输进度观察者
    public private(set) var fileProgressObservers: [WCSessionFileTransfer: NSKeyValueObservation] = [:]
    
    // MARK: activate
    public func activate() {
        let logTag = [Self.logTag, "activate()"]
        guard let session = session else {
            XYLog.info(tag: logTag, process: .fail("session=nil"))
            return
        }
        session.delegate = self
        session.activate()
        XYLog.info(tag: logTag, process: .succ)
    }
}

extension XYWcManager: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        let logTag = [Self.logTag, "activationDidComplete()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "state=\(activationState.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "state=\(activationState.info)")
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        let logTag = [Self.logTag, "reachabilityDidChange()"]
        XYLog.info(tag: logTag, content: "isReachable=\(session.isReachable)")
    }
    
#if os(watchOS)
    
    public func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        let logTag = [Self.logTag, "companionAppInstalledDidChange()"]
        XYLog.info(tag: logTag, content: "isCompanionAppInstalled=\(session.isCompanionAppInstalled)")        
    }
    
#elseif os(iOS)
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        let logTag = [Self.logTag, "didBecomeInactive()"]
        XYLog.info(tag: logTag)
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        let logTag = [Self.logTag, "didDeactivate()"]
        XYLog.info(tag: logTag)
    }
    
    public func sessionWatchStateDidChange(_ session: WCSession) {
        let logTag = [Self.logTag, "watchStateDidChange()"]
        XYLog.info(tag: logTag)
    }
    
#endif
    
}

// MARK: - func
extension XYWcManager {
    func getUsefulSession(logTag: [String], mustReachable: Bool) -> WCSession? {
        guard let session = session else {
            XYLog.info(tag: logTag, process: .fail("session=nil"))
            return nil
        }
        guard session.activationState == .activated else {
            XYLog.info(tag: logTag, process: .fail("activationState!=activated"))
            return nil
        }
        
#if os(watchOS)
    
        guard session.isCompanionAppInstalled else {
            XYLog.info(tag: logTag, process: .fail("isCompanionAppInstalled=false"))
            return nil
        }
        if mustReachable, session.iOSDeviceNeedsUnlockAfterRebootForReachability {
            XYLog.info(tag: logTag, process: .fail("iOSDeviceNeedsUnlockAfterRebootForReachability=true"))
            return nil
        }
        
    
#elseif os(iOS)
    
        guard session.isWatchAppInstalled else {
            XYLog.info(tag: logTag, process: .fail("isWatchAppInstalled=false"))
            return nil
        }
        guard session.isPaired else {
            XYLog.info(tag: logTag, process: .fail("isPaired=false"))
            return nil
        }
    
#endif
        
        if mustReachable {
            guard session.isReachable else {
                XYLog.info(tag: logTag, process: .fail("isReachable=false"))
                return nil
            }
        }
        
        return session
    }
}


// MARK: - appContext
/// 发送方
extension XYWcManager {
    public func updateApplicationContext(dict: [String : Any]) {
        let logTag = [Self.logTag, Self.logTagSender, "updateApplicationContext()"]
        XYLog.info(tag: logTag, process: .begin, content: "context=\(dict.toJSONString())")
        guard let session = getUsefulSession(logTag: logTag, mustReachable: false) else { return }
        do {
            try session.updateApplicationContext(dict)
        } catch let error {
            XYLog.info(tag: logTag, process: .fail("error=\(error.localizedDescription)"))
        }
        XYLog.info(tag: logTag, process: .succ)
    }
}
/// 接收方
extension XYWcManager {
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let logTag = [Self.logTag, Self.logTagReceiver, "didReceiveApplicationContext()"]
        XYLog.info(tag: logTag, content: "context=\(applicationContext.toJSONString())")
    }
}


// MARK: - sendMessageDict
/// 发送方
extension XYWcManager {
    public func sendMessage(dict: [String : Any], replyHandler: (([String : Any]) -> Void)?) {
        let logTag = [Self.logTag, Self.logTagSender, "sendMessageDict()"]
        XYLog.info(tag: logTag, process: .begin, content: "dict=\(dict.toJSONString())")
        guard let session = getUsefulSession(logTag: logTag, mustReachable: true) else { return }
        var newReplyHandler: (([String : Any]) -> Void)?
        if let replyHandler = replyHandler {
            newReplyHandler = {
                message in
                XYLog.info(tag: logTag, process: .succ, content: "didReceiveReplyMessageDict", "dict=\(message.toJSONString())")
                replyHandler(message)
            }
        }
        session.sendMessage(dict, replyHandler: newReplyHandler, errorHandler: {
            error in
            XYLog.info(tag: logTag, process: .fail("error=\(error.localizedDescription)"))
        })
        if replyHandler != nil {
            XYLog.info(tag: logTag, process: .succ)
        } else {
            XYLog.info(tag: logTag, process: .doing, content: "waitingReplyMessageDict")
        }
    }
}
/// 接收方
extension XYWcManager {
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let logTag = [Self.logTag, Self.logTagReceiver, "didReceiveMessageDict()"]
        XYLog.info(tag: logTag, content: "dict=\(message.toJSONString())")
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        let logTag = [Self.logTag, Self.logTagReceiver, "didReceiveMessageDictWithReply()"]
        XYLog.info(tag: logTag, content: "dict=\(message.toJSONString())")
    }
}


// MARK: - sendMessageData
/// 发送方
extension XYWcManager {
    public func sendMessage(data: Data, replyHandler: ((Data) -> Void)?) {
        let logTag = [Self.logTag, Self.logTagSender, "sendMessageData()"]
        XYLog.info(tag: logTag, process: .begin, content: "data=\(data.toHexString())")
        guard let session = getUsefulSession(logTag: logTag, mustReachable: true) else { return }
        var newReplyHandler: ((Data) -> Void)?
        if let replyHandler = replyHandler {
            newReplyHandler = {
                messageData in
                XYLog.info(tag: logTag, process: .succ, content: "didReceiveReplyMessageData", "data=\(messageData.toHexString())")
                replyHandler(messageData)
            }
        }
        session.sendMessageData(data, replyHandler: newReplyHandler, errorHandler: {
            error in
            XYLog.info(tag: logTag, process: .fail("error=\(error.localizedDescription)"))
        })
        if replyHandler != nil {
            XYLog.info(tag: logTag, process: .succ)
        } else {
            XYLog.info(tag: logTag, process: .doing, content: "waitingReplyMessageData")
        }
    }
}
/// 接收方
extension XYWcManager {
    public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        let logTag = [Self.logTag, Self.logTagReceiver, "didReceiveMessageData()"]
        XYLog.info(tag: logTag, content: "data=\(messageData.toHexString())")
    }
    
    public func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        let logTag = [Self.logTag, Self.logTagReceiver, "didReceiveMessageDataWithReply()"]
        XYLog.info(tag: logTag, content: "data=\(messageData.toHexString())")
    }
}


// MARK: - transferUserInfo
/// 发送方
extension XYWcManager {
    public func transferUserInfo(dict: [String : Any]) {
        let logTag = [Self.logTag, Self.logTagSender, "transferUserInfo()"]
        XYLog.info(tag: logTag, process: .begin, content: "userInfo=\(dict.toJSONString())")
        guard let session = getUsefulSession(logTag: logTag, mustReachable: false) else { return }
        session.transferUserInfo(dict)
        XYLog.info(tag: logTag, process: .succ)
    }
    public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: (any Error)?) {
        let logTag = [Self.logTag, Self.logTagSender, "didFinishTransferUserInfo()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag)
        }
    }
}
/// 接收方
extension XYWcManager {
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        let logTag = [Self.logTag, Self.logTagReceiver, "didReceiveTransferUserInfo()"]
        XYLog.info(tag: logTag, content: "userInfo=\(userInfo.toJSONString())")
    }
}


// MARK: - transferFile
/// 发送方
extension XYWcManager {
    @discardableResult
    public func transferFile(
        at url: URL,
        metadata: [String: Any]? = nil,
        onProgress: ((Double) -> Void)? = nil,
        onDone: ((Result<Void, Error>) -> Void)? = nil
    ) -> WCSessionFileTransfer? {
        let logTag = [Self.logTag, Self.logTagSender, "transferFile()"]
        XYLog.info(tag: logTag, process: .begin, content: "url=\(url)")
        guard let session = getUsefulSession(logTag: logTag, mustReachable: false) else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else {
            XYLog.info(tag: logTag, process: .fail("fileNotExist"))
            onDone?(.failure(NSError(domain: "WC", code: -1, userInfo: [NSLocalizedDescriptionKey: "fileNotExist"])))
            return nil
        }
        let transfer = session.transferFile(url, metadata: metadata)
        if let onProgress = onProgress {
            let obs = transfer.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
                DispatchQueue.main.async {
                    onProgress(progress.fractionCompleted)
                }
            }
            fileProgressObservers[transfer] = obs
        }
        FileTransferCallbackRegistry.shared.register(transfer: transfer, onDone: onDone)
        return transfer
    }
    
    public func cancelAllFileTransfers() {
        let logTag = [Self.logTag, Self.logTagSender, "cancelAllFileTransfers()"]
        XYLog.info(tag: logTag)
        session?.outstandingFileTransfers.forEach { $0.cancel() }
    }
    
    public func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: (any Error)?) {
        let logTag = [Self.logTag, Self.logTagSender, "didFinishTransferFile()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag)
        }
    }
}
/// 接收方
extension XYWcManager {
    public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let logTag = [Self.logTag, Self.logTagReceiver, "didReceiveTransferFile()"]
        XYLog.info(tag: logTag, content: "file=\(file.fileURL)")
    }
}
/// FileTransferCallbackRegistry
private final class FileTransferCallbackRegistry {
    static let shared = FileTransferCallbackRegistry()
    private var map = NSMapTable<WCSessionFileTransfer, TransferBox>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    
    func register(transfer: WCSessionFileTransfer, onDone: ((Result<Void, Error>) -> Void)?) {
        guard let onDone = onDone else { return }
        map.setObject(TransferBox(onDone: onDone), forKey: transfer)
    }
    
    func complete(transfer: WCSessionFileTransfer, result: Result<Void, Error>) {
        map.object(forKey: transfer)?.onDone(result)
        map.removeObject(forKey: transfer)
    }
    
    private final class TransferBox {
        let onDone: (Result<Void, Error>) -> Void
        init(onDone: @escaping (Result<Void, Error>) -> Void) {
            self.onDone = onDone
        }
    }
}

