//
//  TVWebSocketHandlerTests.swift
//  
//
//  Created by Amir Daliri.
//

import XCTest
@testable import ControlHub

final class TVWebSocketHandlerTests: XCTestCase {
    private var handler: TVWebSocketHandler!
    private var delegate: MockTVWebSocketHandlerDelegate!

    override func setUp() {
        super.setUp()
        handler = TVWebSocketHandler(url: URL(string: "wss://example.com")!)
        delegate = MockTVWebSocketHandlerDelegate()
        handler.delegate = delegate
    }

    override func tearDown() {
        handler = nil
        delegate = nil
        super.tearDown()
    }

    func testWebSocketDidConnect() {
        handler.connect()
        XCTAssertTrue(delegate.didConnect)
    }

    func testWebSocketDidDisconnect() {
        handler.connect()
        handler.disconnect()
        XCTAssertTrue(delegate.didDisconnect)
    }

    func testReceiveTextWithValidNewAuthPacket() {
        handler.connect()
        let jsonString = #"{"data":{"clients":[{"attributes":{"name":"VGVzdA=="},"connectTime":1713369027676,"deviceName":"VGVzdA==","id":"502e895e-251f-48ca-b786-0f83b20102c5","isHost":false}],"id":"502e895e-251f-48ca-b786-0f83b20102c5","token":"99999999"},"event":"ms.channel.connect"}"#
        if let data = jsonString.data(using: .utf8) {
            handler.sendMessage(String(data: data, encoding: .utf8) ?? "")
        }

        XCTAssertEqual(delegate.didConnect, true)
        XCTAssertNil(delegate.lastError)
    }

    func testReceiveTextWithInvalidPacket() {
        handler.connect()
        let jsonString = "not json"
        if let data = jsonString.data(using: .utf8) {
            handler.sendMessage(String(data: data, encoding: .utf8) ?? "")
        }
        XCTAssertNotNil(delegate.lastError)
    }

    func testReceiveTextWithTimeoutPacket() {
        handler.connect()
        let jsonString = #"{"event":"ms.channel.timeOut"}"#
        if let data = jsonString.data(using: .utf8) {
            handler.sendMessage(String(data: data, encoding: .utf8) ?? "")
        }
        XCTAssertEqual(delegate.lastAuthStatus, TVAuthStatus.none)
    }

    func testReceiveTextWithUnauthorizedPacket() {
        handler.connect()
        let jsonString = #"{"event":"ms.channel.unauthorized"}"#
        if let data = jsonString.data(using: .utf8) {
            handler.sendMessage(String(data: data, encoding: .utf8) ?? "")
        }
        XCTAssertEqual(delegate.lastAuthStatus, .denied)
    }

    func testWebSocketError() {
        handler.connect()
        handler.delegate?.webSocketError(.webSocketError(NSError(domain: "Test", code: 1001, userInfo: nil)))
        XCTAssertNotNil(delegate.lastError)
    }
}

private class MockTVWebSocketHandlerDelegate: TVWebSocketHandlerDelegate {
    var didConnect = false
    var didDisconnect = false
    var lastAuthStatus: TVAuthStatus?
    var lastAuthToken: String?
    var lastError: TVCommanderError?

    func webSocketDidConnect() {
        didConnect = true
    }

    func webSocketDidDisconnect(reason: String, code: UInt16?) {
        didDisconnect = true
    }

    func webSocketDidReadAuthStatus(_ authStatus: TVAuthStatus) {
        lastAuthStatus = authStatus
    }

    func webSocketDidReadAuthToken(_ authToken: String) {
        lastAuthToken = authToken
    }

    func webSocketError(_ error: TVCommanderError) {
        lastError = error
    }
}
