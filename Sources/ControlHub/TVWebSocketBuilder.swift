/// TVWebSocketBuilder.swift
/// Implements the builder pattern to create instances of TVWebSocketHandler with the required configurations.
/// Created by Amir Daliri.

import Foundation

/// A builder class responsible for creating and configuring `TVWebSocketHandler` instances.
class TVWebSocketBuilder {
    
    private var urlRequest: URLRequest?
    private var delegate: TVWebSocketHandlerDelegate?

    /// Sets the `URLRequest` to be used by the WebSocket handler.
    /// - Parameter urlRequest: The `URLRequest` containing the URL for the WebSocket connection.
    func setURLRequest(_ urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
    
    /// Sets the delegate to handle WebSocket events.
    /// - Parameter delegate: The delegate that will handle WebSocket events.
    func setDelegate(_ delegate: TVWebSocketHandlerDelegate) {
        self.delegate = delegate
    }
    
    /// Builds and returns a configured `TVWebSocketHandler` instance.
    /// - Returns: A `TVWebSocketHandler` instance or `nil` if the required properties are not set.
    func getWebSocketHandler() -> TVWebSocketHandler? {
        guard let urlRequest = urlRequest else { return nil }
        let url = urlRequest.url!
        let handler = TVWebSocketHandler(url: url)
        handler.delegate = delegate
        return handler
    }
}
