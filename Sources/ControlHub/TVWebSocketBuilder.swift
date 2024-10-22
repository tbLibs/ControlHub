//
//  TVWebSocketBuilder.swift
//  
//
//  Created by Amir Daliri.
//

import Foundation

class TVWebSocketBuilder {
    
    private var urlRequest: URLRequest?
    private var delegate: TVWebSocketHandlerDelegate?

    func setURLRequest(_ urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
    
    func setDelegate(_ delegate: TVWebSocketHandlerDelegate) {
        self.delegate = delegate
    }
    
    func getWebSocketHandler() -> TVWebSocketHandler? {
        guard let urlRequest = urlRequest else { return nil }
        let url = urlRequest.url!
        let handler = TVWebSocketHandler(url: url)
        handler.delegate = delegate
        return handler
    }
}
