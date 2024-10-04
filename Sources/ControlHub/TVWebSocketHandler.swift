//
//  TVWebSocketHandler.swift
//  
//
//  Created by Amir Daliri.
//

import Foundation
import Starscream

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

    // MARK: Interact with WebSocket

    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            delegate?.webSocketDidConnect()
        case .cancelled:
            delegate?.webSocketDidDisconnect(reason: "cancelled", code: nil)
        case .disconnected(let reason, let code):
            delegate?.webSocketDidDisconnect(reason: reason, code: code)
        case .text(let text):
            handleWebSocketText(text)
        case .binary(let data):
            webSocketDidReadPacket(data)
        case .error(let error):
            delegate?.webSocketError(.webSocketError(error))
        default:
            break
        }
    }

    private func handleWebSocketText(_ text: String) {
        if let packetData = text.asData {
            webSocketDidReadPacket(packetData)
        } else {
            delegate?.webSocketError(.packetDataParsingFailed)
        }
    }

    private func webSocketDidReadPacket(_ packet: Data) {
        if let authResponse = parseAuthResponse(from: packet) {
            handleAuthResponse(authResponse)
        }
        // TODO:  Handle lost token state
//        else {
//            delegate?.webSocketError(.packetDataParsingFailed)
//        }
    }

    // MARK: Receive Auth

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
}
