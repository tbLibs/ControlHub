//
//  TVCommander.swift
//
//
//  Created by Amir Daliri.
//

import Foundation
import Network
import UIKit

public protocol TVCommanderDelegate: AnyObject {
    func tvCommanderDidConnect(_ tvCommander: TVCommander, connectCalledForReconnect: Bool?)
    func tvCommanderDidDisconnect(_ tvCommander: TVCommander, reason: String, code: String?)
    func tvCommander(_ tvCommander: TVCommander, didUpdateAuthState authStatus: TVAuthStatus, connectCalledForReconnect: Bool?)
    func tvCommander(_ tvCommander: TVCommander, didWriteRemoteCommand command: TVRemoteCommand)
    func tvCommander(_ tvCommander: TVCommander, didEncounterError error: TVCommanderError)
    func tvCommander(_ tvCommander: TVCommander, didReceive text: String)
}

public enum ConnectionRequestState {
    case connect
    case reconnect
    case disconnect
}

public class TVCommander: TVWebSocketHandlerDelegate {
    public weak var delegate: TVCommanderDelegate?
    private(set) public var tvConfig: TVConnectionConfiguration
    private(set) public var authStatus = TVAuthStatus.none
    private(set) public var isConnected = false
    private let webSocketCreator: TVWebSocketCreator
    public var webSocketHandler: TVWebSocketHandler?
    private var commandQueue = [TVRemoteCommand]()
    private let logger = ControlHubLogger(category: "TVCommander")
    private var connectionTimeoutTimer: Timer?
    private var connectCalledForReconnect: Bool?

    init(tvConfig: TVConnectionConfiguration, webSocketCreator: TVWebSocketCreator) {
        self.tvConfig = tvConfig
        self.webSocketCreator = webSocketCreator
    }

    public convenience init(tvId: String? = nil, tvIPAddress: String, appName: String, authToken: TVAuthToken? = nil) throws {
        guard appName.isValidAppName else {
            throw TVCommanderError.invalidAppNameEntered
        }
        guard tvIPAddress.isValidIPAddress else {
            throw TVCommanderError.invalidIPAddressEntered
        }
        let tvConfig = TVConnectionConfiguration(
            id: tvId,
            app: appName,
            path: "/api/v2/channels/samsung.remote.control",
            ipAddress: tvIPAddress,
            port: 8002,
            scheme: "wss",
            token: authToken
        )
        self.init(tvConfig: tvConfig, webSocketCreator: TVWebSocketCreator())
        self.logger.info("Initializing TVCommander with configuration: \(tvConfig)")
    }

    public convenience init(tv: TV, appName: String, authToken: TVAuthToken? = nil) throws {
        guard let ipAddress = tv.ipAddress else { throw TVCommanderError.invalidIPAddressEntered }
        try self.init(tvId: tv.id, tvIPAddress: ipAddress, appName: appName, authToken: authToken)
    }

    // MARK: Establish WebSocket Connection
    
    /// **NOTE**
    /// make sure any value for `certPinner` inputted here doesn't strongly reference `TVCommander` (will cause a retain cycle if it does)
    ///
    /// for example:
    ///
    /// **this is okay**
    /// class Client: TVCommanderDelegate
    ///     let certPinner: CustomCertPinner
    ///     let tvCommander: TVCommander
    ///     func connectTVCommander()
    ///         tvCommander.connectToTV(certPinner: certPinner)
    ///
    /// **this is also okay**
    /// class Client: TVCommanderDelegate
    ///     let tvCommander: TVCommander
    ///     func connectTVCommander()
    ///         let certPinner = CustomCertPinner()
    ///         tvCommander.connectToTV(certPinner: certPinner)
    ///
    /// **this will leak**
    /// class Client: TVCommanderDelegate, CertificatePinning
    ///     let tvCommander: TVCommander
    ///     func connectTVCommander()
    ///         tvCommander.connectToTV(certPinner: self)
    ///
    public func connectToTV(isForReconnection: Bool? = false) {
        connectCalledForReconnect = isForReconnection
        if isConnected {
            disconnectFromTV()
        }
        guard let url = tvConfig.wssURL() else {
            handleError(.urlConstructionFailed)
            return
        }
        webSocketHandler = webSocketCreator.createTVWebSocket(url: url, delegate: self)
        webSocketHandler?.connect()
        logger.info("Connecting to TV with URL: \(url)")
        if isForReconnection == false {
            startConnectionTimeoutTimer()
        }
    }

    private func startConnectionTimeoutTimer() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self, !self.isConnected else { return }
            self.handleError(.pairingFailed)
        }
    }
    
    private func invalidateConnectionTimeoutTimer() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
    }
    
    // MARK: Send Remote Control Commands

    public func sendRemoteCommand(key: TVRemoteCommand.Params.ControlKey) {
        guard isConnected else {
            handleError(.remoteCommandNotConnectedToTV)
            return
        }
        guard authStatus == .allowed else {
            handleError(.remoteCommandAuthenticationStatusNotAllowed)
            return
        }
        sendCommandOverWebSocket(createRemoteCommand(key: key))
    }

    private func createRemoteCommand(key: TVRemoteCommand.Params.ControlKey) -> TVRemoteCommand {
        let params = TVRemoteCommand.Params(cmd: .click, dataOfCmd: key, option: false, typeOfRemote: .remoteKey)
        return TVRemoteCommand(method: .control, params: params)
    }
    
    // MARK: Send Mouse Movement Commands

    public func moveMouse(dx: Int, dy: Int) {
        guard isConnected else {
            handleError(.remoteCommandNotConnectedToTV)
            return
        }
        guard authStatus == .allowed else {
            handleError(.remoteCommandAuthenticationStatusNotAllowed)
            return
        }
        let position = TVRemoteCommand.Position(x: dx, y: dy, time: 1)
        sendCommandOverWebSocket(createMouseRemoteCommand(position: position))
    }

    
    private func createMouseRemoteCommand(position: TVRemoteCommand.Position) -> TVRemoteCommand {
        let params = TVRemoteCommand.Params(cmd: .move, option: nil, typeOfRemote: .mouseDevice, position: position)
        return TVRemoteCommand(method: .control, params: params)
        /*
         Mock command that sending for mouse
         let command = """
         {
             "method":"ms.remote.control",
             "params":{
                 "Cmd":"Move",
                 "Position":{
                     "x":\(position.x),
                     "y":\(position.y),
                     "Time":"\(position.time)"
                 },
                 "TypeOfRemote":"ProcessMouseDevice"
             }
         }
         """
         */
    }

    private func createMouseRemoteCommandClick() -> TVRemoteCommand {
        let params = TVRemoteCommand.Params(cmd: .leftClick, option: nil, typeOfRemote: .mouseDevice)
        return TVRemoteCommand(method: .control, params: params)
    }
    
    public func sendInputString(text: String) {
        guard isConnected else {
            handleError(.remoteCommandNotConnectedToTV)
            return
        }
        guard authStatus == .allowed else {
            handleError(.remoteCommandAuthenticationStatusNotAllowed)
            return
        }
        
        if let base64Text = text.asBase64 {
            sendCommandOverWebSocket(createKeyboardStringCommand(inputString: base64Text))
        }
        
    }
    
    private func createKeyboardStringCommand(inputString: String) -> TVRemoteCommand {
        let params = TVRemoteCommand.Params(cmd: inputString, dataOfCmd: .base64, typeOfRemote: .inputString)
        return TVRemoteCommand(method: .control, params: params)
    }

    private func sendCommandOverWebSocket(_ command: TVRemoteCommand) {
        commandQueue.append(command)
        if commandQueue.count == 1 {
            sendNextQueuedCommandOverWebSocket()
        }
    }

    private func sendNextQueuedCommandOverWebSocket() {
        guard let command = commandQueue.first else {
            return
        }
        guard let commandStr = try? command.asString() else {
            handleError(.commandConversionToStringFailed)
            return
        }
        webSocketHandler?.sendMessage(commandStr)
        commandQueue.removeFirst()
        delegate?.tvCommander(self, didWriteRemoteCommand: command)
        sendNextQueuedCommandOverWebSocket()
    }
    
    // MARK: Send Keyboard Commands
    
    public func enterText(_ text: String, on keyboard: TVKeyboardLayout) {
        let keys = controlKeys(toEnter: text, on: keyboard)
        keys.forEach(sendRemoteCommand(key:))
    }

    private func controlKeys(toEnter text: String, on keyboard: TVKeyboardLayout) -> [TVRemoteCommand.Params.ControlKey] {
        let chars = Array(text)
        var moves: [TVRemoteCommand.Params.ControlKey] = [.enter]
        for i in 0..<(chars.count - 1) {
            let currentChar = String(chars[i])
            let nextChar = String(chars[i + 1])
            if let movesToNext = controlKeys(toMoveFrom: currentChar, to: nextChar, on: keyboard) {
                moves.append(contentsOf: movesToNext)
                moves.append(.enter)
            } else {
                delegate?.tvCommander(self, didEncounterError: .keyboardCharNotFound(nextChar))
            }
        }
        return moves
    }

    private func controlKeys(toMoveFrom char1: String, to char2: String, on keyboard: TVKeyboardLayout) -> [TVRemoteCommand.Params.ControlKey]? {
        guard let (startRow, startCol) = coordinates(of: char1, on: keyboard),
              let (endRow, endCol) = coordinates(of: char2, on: keyboard) else {
            return nil
        }
        let rowDiff = endRow - startRow
        let colDiff = endCol - startCol
        var moves: [TVRemoteCommand.Params.ControlKey] = []
        if rowDiff > 0 {
            moves += Array(repeating: .down, count: rowDiff)
        } else if rowDiff < 0 {
            moves += Array(repeating: .up, count: abs(rowDiff))
        }
        if colDiff > 0 {
            moves += Array(repeating: .right, count: colDiff)
        } else if colDiff < 0 {
            moves += Array(repeating: .left, count: abs(colDiff))
        }
        return moves
    }

    private func coordinates(of char: String, on keyboard: TVKeyboardLayout) -> (Int, Int)? {
        for (row, rowChars) in keyboard.enumerated() {
            if let colIndex = rowChars.firstIndex(of: char) {
                return (row, colIndex)
            }
        }
        return nil
    }

    // MARK: Disconnect WebSocket Connection

    public func disconnectFromTV() {
        webSocketHandler?.disconnect()
        isConnected = false
        invalidateConnectionTimeoutTimer()// Invalidate timer on disconnection
    }

    // MARK: Handler Errors

    private func handleError(_ error: TVCommanderError) {
        logger.critical("Error: \(error.errorDescription ?? "Unknown error")")
        delegate?.tvCommander(self, didEncounterError: error)
    }

    // MARK: Wake on LAN

    public static func wakeOnLAN(
        device: TVWakeOnLANDevice,
        queue: DispatchQueue = .global(),
        completion: @escaping (TVCommanderError?) -> Void
    ) {
        let connection = NWConnection(
            host: .init(device.broadcast),
            port: .init(rawValue: device.port)!,
            using: .udp
        )
        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                connection.send(
                    content: .magicPacket(from: device),
                    completion: .contentProcessed({
                        connection.cancel()
                        completion($0.flatMap(TVCommanderError.wakeOnLANProcessingError))
                    })
                )
            case .failed(let error):
                completion(.wakeOnLANConnectionError(error))
            default:
                break
            }
        }
        connection.start(queue: queue)
    }
}

// MARK: TVWebSocketHandlerDelegate
extension TVCommander {
//    func webSocketDidConnect() {
//        isConnected = true
//        invalidateConnectionTimeoutTimer() // Invalidate timer on successful connection
//        delegate?.tvCommanderDidConnect(self)
//        logger.debug("WebSocket connected")
//    }
    
    
    func webSocketDidDisconnect(reason: String, code: String?) {
        isConnected = false
        authStatus = .none
        webSocketHandler = nil
        invalidateConnectionTimeoutTimer() // Invalidate timer on disconnection
        delegate?.tvCommanderDidDisconnect(self, reason: reason, code: code)
        logger.debug("WebSocket disconnected: \(reason)")
    }
    
    func webSocketDidReadAuthStatus(_ authStatus: TVAuthStatus) {
        self.authStatus = authStatus
        isConnected = authStatus == .allowed
        delegate?.tvCommander(self, didUpdateAuthState: authStatus, connectCalledForReconnect: connectCalledForReconnect)
        logger.debug("WebSocket auth status: \(authStatus)")
    }
    
    func webSocketDidReadAuthToken(_ authToken: String) {
        tvConfig.token = authToken
        logger.debug("WebSocket auth token: \(authToken)")
    }
    
    func webSocketError(_ error: TVCommanderError) {
        switch error {
        case .pairingFailed, .webSocketRejectedFromDevice:
            if !(connectCalledForReconnect ?? false) && !isConnected {
                delegate?.tvCommander(self, didEncounterError: error)
            }
        default:
            delegate?.tvCommander(self, didEncounterError: error)
        }
        logger.critical("WebSocket error: \(error)")
    }
    
    func webSocketDidReceive(_ text: String) {
        delegate?.tvCommander(self, didReceive: text)
    }
    
}
