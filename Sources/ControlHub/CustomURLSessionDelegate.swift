/// CustomURLSessionDelegate.swift
/// Handles SSL certificate challenges and provides credentials for trusted server connections.
/// Created by Amir Daliri on 21.10.2024.

import Foundation
import Network

/// A custom `URLSessionDelegate` to handle SSL certificate challenges.
class CustomURLSessionDelegate: NSObject, URLSessionDelegate {
    /// Handles authentication challenges received by the URL session.
    /// - Parameters:
    ///   - session: The URL session that received the authentication challenge.
    ///   - challenge: The authentication challenge that was received.
    ///   - completionHandler: A completion handler that your delegate method must call to resolve the challenge.
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            // If the server is trusted, use the provided credentials to proceed.
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Perform default handling for any other type of challenge.
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
