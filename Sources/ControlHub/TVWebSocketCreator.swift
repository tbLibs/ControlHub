//
//  TVWebSocketCreator.swift
//  
//
//  Created by Amir Daliri.
//

import Foundation
import Network
import UIKit

class TVWebSocketCreator {
    let builder: TVWebSocketBuilder

    init(builder: TVWebSocketBuilder = TVWebSocketBuilder()) {
        self.builder = builder
    }

    func createTVWebSocket(
        url: URL,
        certPinner: TVCertificatePinning? = TVDefaultWebSocketCertPinner(),
        delegate: TVWebSocketHandlerDelegate
    ) -> TVWebSocketHandler? {
        let urlRequest = URLRequest(url: url)
        builder.setURLRequest(urlRequest)
        builder.setDelegate(delegate)
        return builder.getWebSocketHandler()
    }
}

enum PinningState {
    case success
    case failure(Error)
}

protocol TVCertificatePinning {
    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ()))
}

class TVDefaultWebSocketCertPinner: TVCertificatePinning {
    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ())) {
        completion(.success)
    }
}
