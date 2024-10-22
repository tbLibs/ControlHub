//
//  TVWebSocketHandler.swift
//  
//
//  Created by Amir Daliri.
//

import Foundation

protocol TVWebSocketHandlerDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect(reason: String, code: UInt16?)
    func webSocketDidReadAuthStatus(_ authStatus: TVAuthStatus)
    func webSocketDidReadAuthToken(_ authToken: String)
    func webSocketError(_ error: TVCommanderError)
}

class TVWebSocketHandler {
    private let decoder = JSONDecoder()
    weak var delegate: TVWebSocketHandlerDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession

    init(url: URL) {
        let configuration = URLSessionConfiguration.default
        let sessionDelegate = CustomURLSessionDelegate()
        urlSession = URLSession(configuration: configuration, delegate: sessionDelegate, delegateQueue: nil)
        webSocketTask = urlSession.webSocketTask(with: url)
    }

    func connect() {
        webSocketTask?.resume()
        listenForMessages()
        delegate?.webSocketDidConnect()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        delegate?.webSocketDidDisconnect(reason: "Manual Disconnect", code: nil)
    }

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                self?.delegate?.webSocketError(.webSocketError(error))
                self?.reconnectIfNecessary()
            case .success(let message):
                switch message {
                case .data(let data):
                    self?.webSocketDidReadPacket(data)
                case .string(let text):
                    if let packetData = text.data(using: .utf8) {
                        self?.webSocketDidReadPacket(packetData)
                    } else {
                        self?.delegate?.webSocketError(.packetDataParsingFailed)
                    }
                @unknown default:
                    break
                }
                self?.listenForMessages() // Continue listening for the next message
            }
        }
    }

    private func reconnectIfNecessary() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.connect()
        }
    }

    private func webSocketDidReadPacket(_ packet: Data) {
        if let authResponse = parseAuthResponse(from: packet) {
            handleAuthResponse(authResponse)
        } else {
            delegate?.webSocketError(.packetDataParsingFailed)
        }
    }

    private func parseAuthResponse(from packet: Data) -> TVAuthResponse? {
        try? decoder.decode(TVAuthResponse.self, from: packet)
    }

    private func handleAuthResponse(_ response: TVAuthResponse) {
        switch response.event {
        case .connect:
            delegate?.webSocketDidReadAuthStatus(.allowed)
            parseTokenFromAuthResponse(response)
        case .unauthorized:
            delegate?.webSocketDidReadAuthStatus(.denied)
        case .timeout:
            delegate?.webSocketDidReadAuthStatus(.none)
        default:
            delegate?.webSocketError(.authResponseUnexpectedChannelEvent(response))
        }
    }

    private func parseTokenFromAuthResponse(_ response: TVAuthResponse) {
        if let newToken = response.data?.token {
            delegate?.webSocketDidReadAuthToken(newToken)
        } else if let refreshedToken = response.data?.clients?.first?.attributes.token {
            delegate?.webSocketDidReadAuthToken(refreshedToken)
        } else {
            delegate?.webSocketError(.noTokenInAuthResponse(response))
        }
    }

    // Additional method to send a message
    func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                self?.delegate?.webSocketError(.webSocketError(error))
            }
        }
    }
}
