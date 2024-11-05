/// TVWebSocketHandler.swift
/// Handles WebSocket communication for TV control, managing connection, reconnection, message listening, and delegation.
/// Created by Amir Daliri.

import Foundation

/// Protocol defining the delegate methods for WebSocket events.
protocol TVWebSocketHandlerDelegate: AnyObject {
    /// Called when the WebSocket successfully connects.
    func webSocketDidConnect()
    
    /// Called when the WebSocket disconnects.
    /// - Parameters:
    ///   - reason: The reason for the disconnection.
    ///   - code: The close code if available.
    func webSocketDidDisconnect(reason: String, code: String?)
    
    /// Called when the WebSocket reads an authentication status.
    /// - Parameter authStatus: The authentication status received from the TV.
    func webSocketDidReadAuthStatus(_ authStatus: TVAuthStatus)
    
    /// Called when the WebSocket reads an authentication token.
    /// - Parameter authToken: The authentication token received from the TV.
    func webSocketDidReadAuthToken(_ authToken: String)
    
    /// Called when an error occurs in the WebSocket.
    /// - Parameter error: The error that occurred.
    func webSocketError(_ error: TVCommanderError)
}

/// Class responsible for managing the WebSocket connection to a TV, including connection, disconnection, and message handling.
class TVWebSocketHandler {
    private let decoder = JSONDecoder() // JSON decoder to parse incoming WebSocket messages.
    weak var delegate: TVWebSocketHandlerDelegate? // Delegate to receive WebSocket events.
    private var webSocketTask: URLSessionWebSocketTask? // WebSocket task for managing the connection.
    private let urlSession: URLSession // URLSession to manage networking tasks.
    private let logger = ControlHubLogger(category: "TVWebSocketHandler")
    private var checkConnectionTimeout = true
    private var needToListenWebSocket = true

    /// Initializes a new instance of `TVWebSocketHandler`.
    /// - Parameter url: The URL of the WebSocket endpoint for the TV connection.
    init(url: URL) {
        let configuration = URLSessionConfiguration.default
        let sessionDelegate = CustomURLSessionDelegate()
        urlSession = URLSession(configuration: configuration, delegate: sessionDelegate, delegateQueue: nil)
        webSocketTask = urlSession.webSocketTask(with: url)
        logger.debug("Initialized TVWebSocketHandler with URL: \(url)")
    }

    /// Establishes the WebSocket connection and starts listening for messages.
    func connect() {
        webSocketTask?.resume()

        // Implement a timeout to detect if the connection fails.
        DispatchQueue.main.asyncAfter(deadline: .now() + 35) { [weak self] in
            guard let self = self else { return }
            if self.checkConnectionTimeout {
                if self.webSocketTask?.state != .running {
                    self.delegate?.webSocketDidDisconnect(reason: "Connection timeout", code: nil)
                    self.webSocketTask?.cancel()
                    self.checkConnectionTimeout = false
                    logger.error("Connection timeout")
                }
            }
        }
        needToListenWebSocket = true
        listenForMessages()
        // TODO:  check real connection staus befor send this
        delegate?.webSocketDidConnect()
        logger.debug("Connected to TV")
    }

    /// Disconnects the WebSocket connection.
    /// Notifies the delegate about the disconnection.
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        delegate?.webSocketDidDisconnect(reason: "Manual Disconnect", code: nil)
        logger.critical("Disconnected from TV")
    }

    /// Listens for incoming messages from the WebSocket.
    private func listenForMessages() {
        guard needToListenWebSocket else { return }
        
        webSocketTask?.receive { [weak self] result in
            self?.checkConnectionTimeout = false
            
            switch result {
            case .failure(let error as NSError):
                self?.webSocketTask?.cancel()
                // Handle specific WebSocket rejection error.
                if error.domain == NSPOSIXErrorDomain && error.code == 57 {
                    self?.delegate?.webSocketError(.webSocketRejectedFromDevice(error))
                    self?.logger.critical("WebSocket rejected from device with error: \(error)")
                    self?.logger.critical("WebSocket rejected from device with error code: \(error.code)")
                } else {
                    self?.delegate?.webSocketError(.webSocketError(error))
                    self?.delegate?.webSocketDidDisconnect(reason: error.localizedDescription, code: String(error.code))
                    // Attempt to reconnect if necessary.
                    self?.reconnectIfNecessary()
                    self?.logger.critical("WebSocket error: \(error)")
                }
                
            case .success(let message):
                // Handle different types of WebSocket messages.
                switch message {
                case .data(let data):
                    self?.webSocketDidReadPacket(data)
                    self?.logger.debug("Received WebSocket data: \(data)")
                case .string(let text):
                    if let packetData = text.data(using: .utf8) {
                        self?.webSocketDidReadPacket(packetData)
                        self?.logger.debug("Received WebSocket text: \(text)")
                    } else {
                        self?.delegate?.webSocketError(.packetDataParsingFailed)
                        self?.logger.critical("Failed to parse WebSocket text: \(text)")
                    }
                @unknown default:
                    break
                }
                // Continue listening for the next message.
                self?.listenForMessages()
            }
        }
    }

    /// Attempts to reconnect the WebSocket after a delay.
    private func reconnectIfNecessary() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.connect()
            self.logger.debug("recursive reconnect attempt")
        }
    }

    /// Handles incoming packet data from the WebSocket.
    /// - Parameter packet: The data packet received from the WebSocket.
    private func webSocketDidReadPacket(_ packet: Data) {
        if let authResponse = parseAuthResponse(from: packet) {
            handleAuthResponse(authResponse)
        } else {
            delegate?.webSocketError(.packetDataParsingFailed)
        }
    }

    /// Parses the authentication response from the given packet.
    /// - Parameter packet: The data packet to parse.
    /// - Returns: A `TVAuthResponse` object if parsing is successful, otherwise `nil`.
    private func parseAuthResponse(from packet: Data) -> TVAuthResponse? {
        try? decoder.decode(TVAuthResponse.self, from: packet)
    }

    /// Handles the authentication response received from the TV.
    /// - Parameter response: The authentication response to handle.
    private func handleAuthResponse(_ response: TVAuthResponse) {
        logger.debug("received auth response: \(response)")
        switch response.event {
        case .connect:
            delegate?.webSocketDidReadAuthStatus(.allowed)
            parseTokenFromAuthResponse(response)
        case .unauthorized:
            delegate?.webSocketDidReadAuthStatus(.denied)
        case .timeout:
            needToListenWebSocket = false
            webSocketTask?.cancel()
            delegate?.webSocketDidReadAuthStatus(.none)
        default:
            delegate?.webSocketError(.authResponseUnexpectedChannelEvent(response))
        }
    }

    /// Parses the token from the authentication response and notifies the delegate.
    /// - Parameter response: The authentication response containing the token.
    private func parseTokenFromAuthResponse(_ response: TVAuthResponse) {
        if let newToken = response.data?.token {
            delegate?.webSocketDidReadAuthToken(newToken)
        } else if let refreshedToken = response.data?.clients?.first?.attributes.token {
            delegate?.webSocketDidReadAuthToken(refreshedToken)
        } else {
            delegate?.webSocketError(.noTokenInAuthResponse(response))
        }
    }

    /// Sends a message over the WebSocket.
    /// - Parameter message: The message to be sent.
    func sendMessage(_ message: String) {
        logger.debug("Sending message: \(message)")
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                self?.logger.error("Error sending message: \(error)")
                self?.delegate?.webSocketError(.webSocketError(error))
            }
        }
    }
}
