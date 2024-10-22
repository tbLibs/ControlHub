/// TVWebSocketCreator.swift
/// Responsible for creating instances of TVWebSocketHandler using the builder pattern.
/// Created by Amir Daliri.

import Foundation
import Network
import UIKit

/// A class responsible for creating and configuring `TVWebSocketHandler` instances.
class TVWebSocketCreator {
    let builder: TVWebSocketBuilder

    /// Initializes the creator with a `TVWebSocketBuilder`.
    /// - Parameter builder: The builder used to create `TVWebSocketHandler` instances.
    init(builder: TVWebSocketBuilder = TVWebSocketBuilder()) {
        self.builder = builder
    }

    /// Creates a `TVWebSocketHandler` configured with the given URL, certificate pinner, and delegate.
    /// - Parameters:
    ///   - url: The URL to which the WebSocket will connect.
    ///   - certPinner: Optional certificate pinning implementation for SSL validation. Defaults to `TVDefaultWebSocketCertPinner`.
    ///   - delegate: The delegate that handles WebSocket events.
    /// - Returns: A configured `TVWebSocketHandler` instance or `nil` if creation fails.
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

/// Enum representing the state of SSL certificate pinning.
enum PinningState {
    case success
    case failure(Error)
}

/// Protocol defining certificate pinning evaluation.
protocol TVCertificatePinning {
    /// Evaluates the SSL certificate trust for a given domain.
    /// - Parameters:
    ///   - trust: The trust object representing the certificate chain.
    ///   - domain: The domain to validate.
    ///   - completion: Completion handler providing the result of the pinning evaluation.
    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ()))
}

/// Default implementation of `TVCertificatePinning` that trusts all connections.
class TVDefaultWebSocketCertPinner: TVCertificatePinning {
    /// Evaluates trust by automatically succeeding, effectively trusting all certificates.
    /// - Parameters:
    ///   - trust: The trust object representing the certificate chain.
    ///   - domain: The domain to validate.
    ///   - completion: Completion handler providing the success state.
    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ())) {
        completion(.success)
    }
}
