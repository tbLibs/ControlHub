//
//  TVCommander+Errors.swift
//  
//
//  Created by Amir Daliri.
//

import Foundation

public enum TVCommanderError: Error {
    // invalid app name
    case invalidAppNameEntered
    // invalid ip address
    case invalidIPAddressEntered
    // trying to connect, but the connection is already established.
    case connectionAlreadyEstablished
    // the URL could not be constructed.
    case urlConstructionFailed
    // WebSocket receives an error.
    case webSocketError(Error?)
    // parsing for packet data fails.
    case packetDataParsingFailed
    // response for authentication contains unexpected event
    case authResponseUnexpectedChannelEvent(TVAuthResponse)
    // no token is found inside an allowed authentication response.
    case noTokenInAuthResponse(TVAuthResponse)
    // trying to send a command without being connected to a TV
    case remoteCommandNotConnectedToTV
    // trying to send a command when authentication status is not allowed.
    case remoteCommandAuthenticationStatusNotAllowed
    // command conversion to a string fails.
    case commandConversionToStringFailed
    // invalid input to keyboard navigation
    case keyboardCharNotFound(String)
    // wake on LAN connection error
    case wakeOnLANConnectionError(Error)
    // wake on LAN content processing error
    case wakeOnLANProcessingError(Error)
    // No service is connected when attempting to launch the app.
    case noServiceConnected
    // Failed to create the application for the specified appID and channelURI.
    case appCreationFailed
    // Error occurred while connecting to the app.
    case connectionError(Error)    
    // Error occurred while launching the app.
    case launchError(Error)
    // an unknown error occurs.
    case unknownError(Error?)
}

extension TVCommanderError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .invalidAppNameEntered:
            return NSLocalizedString("The app name entered is invalid.", comment: "")
        case .invalidIPAddressEntered:
            return NSLocalizedString("The IP address entered is invalid.", comment: "")
        case .connectionAlreadyEstablished:
            return NSLocalizedString("Attempted to connect, but the connection is already established.", comment: "")
        case .urlConstructionFailed:
            return NSLocalizedString("Failed to construct the URL.", comment: "")
        case .webSocketError(let error):
            return NSLocalizedString("WebSocket encountered an error: \(error?.localizedDescription ?? "Unknown error").", comment: "")
        case .packetDataParsingFailed:
            return NSLocalizedString("Failed to parse the packet data.", comment: "")
        case .authResponseUnexpectedChannelEvent(_):
            return NSLocalizedString("The authentication response contains an unexpected event.", comment: "")
        case .noTokenInAuthResponse(_):
            return NSLocalizedString("No token found in the authentication response.", comment: "")
        case .remoteCommandNotConnectedToTV:
            return NSLocalizedString("Attempted to send a command without being connected to a TV.", comment: "")
        case .remoteCommandAuthenticationStatusNotAllowed:
            return NSLocalizedString("Attempted to send a command when authentication status is not allowed.", comment: "")
        case .commandConversionToStringFailed:
            return NSLocalizedString("Failed to convert the command to a string.", comment: "")
        case .keyboardCharNotFound(let char):
            return NSLocalizedString("Invalid input provided for keyboard navigation: \(char).", comment: "")
        case .wakeOnLANConnectionError(let error):
            return NSLocalizedString("Wake on LAN connection error: \(error.localizedDescription).", comment: "")
        case .wakeOnLANProcessingError(let error):
            return NSLocalizedString("Error processing Wake on LAN content: \(error.localizedDescription).", comment: "")
        case .noServiceConnected:
            return NSLocalizedString("No service is connected when attempting to launch the app.", comment: "")
        case .appCreationFailed:
            return NSLocalizedString("Failed to create the application for the specified appID and channelURI.", comment: "")
        case .connectionError(let error):
            return NSLocalizedString("Please make sure you have this application installed on your TV.", comment: "")
        case .launchError(let error):
            return NSLocalizedString("Error occurred while launching the app: \(error.localizedDescription).", comment: "")
        case .unknownError(let error):
            return NSLocalizedString("An unknown error occurred: \(error?.localizedDescription ?? "Unknown error").", comment: "")
        }
    }
    
    public var failureReason: String {
        switch self {
        case .invalidAppNameEntered:
            return NSLocalizedString("Invalid App Name", comment: "")
        case .invalidIPAddressEntered:
            return NSLocalizedString("Invalid IP Address", comment: "")
        case .connectionAlreadyEstablished:
            return NSLocalizedString("Connection Already Established", comment: "")
        case .urlConstructionFailed:
            return NSLocalizedString("URL Construction Failed", comment: "")
        case .webSocketError:
            return NSLocalizedString("WebSocket Error", comment: "")
        case .packetDataParsingFailed:
            return NSLocalizedString("Packet Data Parsing Failed", comment: "")
        case .authResponseUnexpectedChannelEvent:
            return NSLocalizedString("Unexpected Channel Event", comment: "")
        case .noTokenInAuthResponse:
            return NSLocalizedString("No Token in Auth Response", comment: "")
        case .remoteCommandNotConnectedToTV:
            return NSLocalizedString("Not Connected to TV", comment: "")
        case .remoteCommandAuthenticationStatusNotAllowed:
            return NSLocalizedString("Authentication Status Not Allowed", comment: "")
        case .commandConversionToStringFailed:
            return NSLocalizedString("Command Conversion Failed", comment: "")
        case .keyboardCharNotFound:
            return NSLocalizedString("Invalid Keyboard Input", comment: "")
        case .wakeOnLANConnectionError:
            return NSLocalizedString("Wake on LAN Connection Error", comment: "")
        case .wakeOnLANProcessingError:
            return NSLocalizedString("Wake on LAN Processing Error", comment: "")
        case .noServiceConnected:
            return NSLocalizedString("No Service Connected", comment: "")
        case .appCreationFailed:
            return NSLocalizedString("App Creation Failed", comment: "")
        case .connectionError:
            return NSLocalizedString("App not found", comment: "")
        case .launchError:
            return NSLocalizedString("Launch Error", comment: "")
        case .unknownError:
            return NSLocalizedString("Unknown Error", comment: "")
        }
    }
}
