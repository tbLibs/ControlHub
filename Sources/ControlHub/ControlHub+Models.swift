//
//  ControlHub+Models.swift
//
//
//  Created by Amir Daliri.
//

import Foundation

/// Represents a TV discovered in a search
public struct TV: Codable, Identifiable, Equatable {
    /// Represents detailed device information for a TV
    public struct Device: Codable, Equatable {
        public let countryCode: String?
        public let deviceDescription: String?
        public let developerIp: String?
        public let developerMode: String?
        public let duid: String?
        public let firmwareVersion: String?
        public let frameTvSupport: String?
        public let gamePadSupport: String?
        /// Unique identifier for the device, often the same as the TV id
        public let id: String?
        public let imeSyncedSupport: String?
        /// IP address of the TV on the network
        public let ip: String?
        public let language: String?
        public let model: String?
        public let modelName: String?
        public let name: String?
        public let networkType: String?
        public let os: String?
        /// Current power state of the TV, e.g., "on", "off", "standby"
        public let powerState: String?
        public let resolution: String?
        public let smartHubAgreement: String?
        public let ssid: String?
        /// Indicates whether the TV supports token-based authorization
        public let tokenAuthSupport: String
        public let type: String?
        public let udn: String?
        public let voiceSupport: String?
        public let wallScreenRatio: String?
        public let wallService: String?
        /// MAC address of the TV's Wi-Fi connection
        public let wifiMac: String

        public init(
            countryCode: String? = nil,
            deviceDescription: String? = nil,
            developerIp: String? = nil,
            developerMode: String? = nil,
            duid: String? = nil,
            firmwareVersion: String? = nil,
            frameTvSupport: String? = nil,
            gamePadSupport: String? = nil,
            id: String? = nil,
            imeSyncedSupport: String? = nil,
            ip: String? = nil,
            language: String? = nil,
            model: String? = nil,
            modelName: String? = nil,
            name: String? = nil,
            networkType: String? = nil,
            os: String? = nil,
            powerState: String? = nil,
            resolution: String? = nil,
            smartHubAgreement: String? = nil,
            ssid: String? = nil,
            tokenAuthSupport: String,
            type: String? = nil,
            udn: String? = nil,
            voiceSupport: String? = nil,
            wallScreenRatio: String? = nil,
            wallService: String? = nil,
            wifiMac: String
        ) {
            self.countryCode = countryCode
            self.deviceDescription = deviceDescription
            self.developerIp = developerIp
            self.developerMode = developerMode
            self.duid = duid
            self.firmwareVersion = firmwareVersion
            self.frameTvSupport = frameTvSupport
            self.gamePadSupport = gamePadSupport
            self.id = id
            self.imeSyncedSupport = imeSyncedSupport
            self.ip = ip
            self.language = language
            self.model = model
            self.modelName = modelName
            self.name = name
            self.networkType = networkType
            self.os = os
            self.powerState = powerState
            self.resolution = resolution
            self.smartHubAgreement = smartHubAgreement
            self.ssid = ssid
            self.tokenAuthSupport = tokenAuthSupport
            self.type = type
            self.udn = udn
            self.voiceSupport = voiceSupport
            self.wallScreenRatio = wallScreenRatio
            self.wallService = wallService
            self.wifiMac = wifiMac
        }

        enum CodingKeys: String, CodingKey {
            case countryCode
            case deviceDescription = "description"
            case developerIp = "developerIP"
            case developerMode
            case duid
            case firmwareVersion
            case frameTvSupport = "FrameTVSupport"
            case gamePadSupport = "GamePadSupport"
            case id
            case imeSyncedSupport = "ImeSyncedSupport"
            case ip
            case language = "Language"
            case model
            case modelName
            case name
            case networkType
            case os = "OS"
            case powerState = "PowerState"
            case resolution
            case smartHubAgreement
            case ssid
            case tokenAuthSupport = "TokenAuthSupport"
            case type
            case udn
            case voiceSupport = "VoiceSupport"
            case wallScreenRatio = "WallScreenRatio"
            case wallService = "WallService"
            case wifiMac
        }
    }

    /// Detailed information about the TV
    public let device: Device?
    /// Unique identifier for the TV
    public let id: String
    public let isSupport: String?
    /// User-friendly name of the TV
    public let name: String
    public let remote: String?
    public let type: String
    /// URI used to query the TV via HTTP
    public let uri: String
    public let version: String?

    public init(
        device: Device? = nil,
        id: String,
        isSupport: String? = nil,
        name: String,
        remote: String? = nil,
        type: String,
        uri: String,
        version: String? = nil
    ) {
        self.device = device
        self.id = id
        self.isSupport = isSupport
        self.name = name
        self.remote = remote
        self.type = type
        self.uri = uri
        self.version = version
    }
}

public enum TVAuthStatus {
    /// Client hasn't completed authorization with TV
    case none
    /// Client is authorized to command TV
    case allowed
    /// Client is denied authorization to command TV
    case denied
}

public typealias TVAuthToken = String

public struct TVConnectionConfiguration {
    public let id: String?
    public let app: String
    public let path: String
    public let ipAddress: String
    public let port: Int
    public let scheme: String
    public var token: TVAuthToken?

    public init(id: String?, app: String, path: String, ipAddress: String, port: Int, scheme: String, token: TVAuthToken?) {
        self.id = id
        self.app = app
        self.path = path
        self.ipAddress = ipAddress
        self.port = port
        self.scheme = scheme
        self.token = token
    }
}

/// Defines the overall command to be sent to the TV
public struct TVRemoteCommand: Codable {
    public enum Method: String, Codable {
        case control = "ms.remote.control"
    }

    public struct Position: Codable {
        public let x: Int
        public let y: Int
        public let time: Int
        
        public init(x: Int, y: Int, time: Int) {
            self.x = x
            self.y = y
            self.time = time
        }
        
        enum CodingKeys: String, CodingKey {
            case x = "x"
            case y = "y"
            case time = "Time"
        }
    }
    
    /// Contains the specific parameters for a remote command
    public struct Params: Codable {
        public enum Command: String, Codable {
            case click = "Click"
            case move = "Move"
            case leftClick = "LeftClick"
        }

        /// Enum representing the keys on a TV's remote control
        public enum ControlKey: String, Codable {
            case power = "KEY_POWER"
            case powerOff = "KEY_POWEROFF"
            case powerOn = "KEY_POWERON"
            case up = "KEY_UP"
            case down = "KEY_DOWN"
            case left = "KEY_LEFT"
            case right = "KEY_RIGHT"
            case enter = "KEY_ENTER"
            case returnKey = "KEY_RETURN"
            case channelList = "KEY_CH_LIST"
            case channelUp = "KEY_CHUP"
            case channelDown = "KEY_CHDOWN"
            case play = "KEY_PLAY"
            case pause = "KEY_PAUSE"
            case stop = "KEY_STOP"
            case rewind = "KEY_REWIND"
            case fastForward = "KEY_FF"
            case record = "KEY_REC"
            case menu = "KEY_MENU"
            case source = "KEY_SOURCE"
            case guide = "KEY_GUIDE"
            case tools = "KEY_TOOLS"
            case info = "KEY_INFO"
            case colorRed = "KEY_RED"
            case colorGreen = "KEY_GREEN"
            case colorYellow = "KEY_YELLOW"
            case colorBlue = "KEY_BLUE"
            case key3D = "KEY_3D"
            case volumeUp = "KEY_VOLUP"
            case volumeDown = "KEY_VOLDOWN"
            case mute = "KEY_MUTE"
            case number0 = "KEY_0"
            case number1 = "KEY_1"
            case number2 = "KEY_2"
            case number3 = "KEY_3"
            case number4 = "KEY_4"
            case number5 = "KEY_5"
            case number6 = "KEY_6"
            case number7 = "KEY_7"
            case number8 = "KEY_8"
            case number9 = "KEY_9"
            case sourceTV = "KEY_TV"
            case sourceHDMI = "KEY_HDMI"
            case contents = "KEY_CONTENTS"
            case home = "KEY_HOME"
            case sleep = "KEY_SLEEP"
            case aspect = "KEY_ASPECT"
            case favoriteChannel = "KEY_FAVCH"
            case quickReplay = "KEY_QUICK_REPLAY"
            case stillPicture = "KEY_STILL_PICTURE"
            case fmRadio = "KEY_FM_RADIO"
            case mts = "KEY_MTS"
            case clear = "KEY_CLEAR"
            case vchip = "KEY_VCHIP"
            case repeatKey = "KEY_REPEAT"
            case door = "KEY_DOOR"
            case open = "KEY_OPEN"
            case wheelLeft = "KEY_WHEEL_LEFT"
            case wheelRight = "KEY_WHEEL_RIGHT"
            case pannelEnter = "KEY_PANNEL_ENTER"
            case pannelMenu = "KEY_PANNEL_MENU"
            case pannelSource = "KEY_PANNEL_SOURCE"
            case av1 = "KEY_AV1"
            case av2 = "KEY_AV2"
            case av3 = "KEY_AV3"
            case component1 = "KEY_COMPONENT1"
            case component2 = "KEY_COMPONENT2"
            case dvi = "KEY_DVI"
            case dnet = "KEY_DNET"
            case hdmi1 = "KEY_HDMI1"
            case hdmi2 = "KEY_HDMI2"
            case hdmi3 = "KEY_HDMI3"
            case hdmi4 = "KEY_HDMI4"
            case ext1 = "KEY_EXT1"
            case ext2 = "KEY_EXT2"
            case ext3 = "KEY_EXT3"
            case ext4 = "KEY_EXT4"
            case ext5 = "KEY_EXT5"
            case ext6 = "KEY_EXT6"
            case ext7 = "KEY_EXT7"
            case ext8 = "KEY_EXT8"
            case ext9 = "KEY_EXT9"
            case ext10 = "KEY_EXT10"
            case ext11 = "KEY_EXT11"
            case ext12 = "KEY_EXT12"
            case ext13 = "KEY_EXT13"
            case ext14 = "KEY_EXT14"
            case ext15 = "KEY_EXT15"
            case ext16 = "KEY_EXT16"
            case ext17 = "KEY_EXT17"
            case ext18 = "KEY_EXT18"
            case ext19 = "KEY_EXT19"
            case ext20 = "KEY_EXT20"
            case ext21 = "KEY_EXT21"
            case ext22 = "KEY_EXT22"
            case ext23 = "KEY_EXT23"
            case ext24 = "KEY_EXT24"
            case ext25 = "KEY_EXT25"
            case ext26 = "KEY_EXT26"
            case ext27 = "KEY_EXT27"
            case ext28 = "KEY_EXT28"
            case ext29 = "KEY_EXT29"
            case ext30 = "KEY_EXT30"
            case ext31 = "KEY_EXT31"
            case ext32 = "KEY_EXT32"
            case ext33 = "KEY_EXT33"
            case ext34 = "KEY_EXT34"
            case ext35 = "KEY_EXT35"
            case ext36 = "KEY_EXT36"
            case ext37 = "KEY_EXT37"
            case ext38 = "KEY_EXT38"
            case ext39 = "KEY_EXT39"
            case ext40 = "KEY_EXT40"
            case ext41 = "KEY_EXT41"
            case base64 = "base64"
            
            // Computed property for dynamic number keys
            public static func dynamicNumberKey(_ number: Int) -> Self {
                return TVRemoteCommand.Params.ControlKey(rawValue: "KEY_\(number)") ?? .number0
            }
        }


        /// [1 - Netflix]
        /// - App Name                            :     Netflix
        /// - App Version                         :     5.2.550
        /// - App ID - WAS                        :     3201907018807
        /// - App ID - Tizen                      :     org.tizen.netflixapp
        /// -----------------------------------------------------------------------------------------------------
        /// [2 - Prime Video]
        /// - App Name                            :     Prime Video
        /// - App Version                         :     2.01.26
        /// - App ID - WAS                        :     3201910019365
        /// - App ID - Tizen                      :     org.tizen.primevideo
        /// -----------------------------------------------------------------------------------------------------
        /// [3 - Hulu]
        /// - App Name                            :     Hulu
        /// - App Version                         :     5.3.263
        /// - App ID - WAS                        :     3201601007625
        /// - App ID - Tizen                      :     LBUAQX1exg.Hulu
        /// -----------------------------------------------------------------------------------------------------
        /// [4 - Disney+]
        /// - App Name                            :     Disney+
        /// - App Version                         :     1.6.0
        /// - App ID - WAS                        :     3201901017640
        /// - App ID - Tizen                      :     MCmYXNxgcu.DisneyPlus
        /// -----------------------------------------------------------------------------------------------------
        /// [5 - Apple TV]
        /// - App Name                            :     Apple TV
        /// - App Version                         :     6.2.2
        /// - App ID - WAS                        :     3201807016597
        /// - App ID - Tizen                      :     com.samsung.tv.ariavideo
        /// -----------------------------------------------------------------------------------------------------
        /// [6 - VUDU]
        /// - App Name                            :     VUDU
        /// - App Version                         :     7.9.39
        /// - App ID - WAS                        :     111012010001
        /// - App ID - Tizen                      :     kk8MbItQ0H.VUDU
        /// -----------------------------------------------------------------------------------------------------
        /// [7 - YouTube]
        /// - App Name                            :     YouTube
        /// - App Version                         :     2.1.498
        /// - App ID - WAS                        :     111299001912
        /// - App ID - Tizen                      :     9Ur5IzDKqV.TizenYouTube
        /// -----------------------------------------------------------------------------------------------------
        /// [8 - Gallery]
        /// - App Name                            :     Gallery
        /// - App Version                         :     1.9.216
        /// - App ID - WAS                        :     3201710015037
        /// - App ID - Tizen                      :     com.samsung.tv.gallery
        /// -----------------------------------------------------------------------------------------------------
        /// [9 - Internet]
        /// - App Name                            :     Internet
        /// - App Version                         :     3.1.11260
        /// - App ID - WAS                        :     3201907018784
        /// - App ID - Tizen                      :     org.tizen.browser
        /// -----------------------------------------------------------------------------------------------------
        /// [10 - Apple Music]
        /// - App Name                            :     Apple Music
        /// - App Version                         :     2.1.0
        /// - App ID - WAS                        :     3201908019041
        /// - App ID - Tizen                      :     org.tizen.apple.applemusic
        /// -----------------------------------------------------------------------------------------------------
        /// [11 - YouTube TV]
        /// - App Name                            :     YouTube TV
        /// - App Version                         :     1.0.81
        /// - App ID - WAS                        :     3201707014489
        /// - App ID - Tizen                      :     PvWgqxV3Xa.YouTubeTV
        /// -----------------------------------------------------------------------------------------------------
        /// [12 - Tubi Free Movies ＆ TV]
        /// - App Name                            :     Tubi Free Movies ＆ TV
        /// - App Version                         :     2.0.26
        /// - App ID - WAS                        :     3201504001965
        /// - App ID - Tizen                      :     3KA0pm7a7V.TubiTV
        /// -----------------------------------------------------------------------------------------------------
        /// [13 - Spotify Music and Podcasts]
        /// - App Name                            :     Spotify Music and Podcasts
        /// - App Version                         :     1.7.2
        /// - App ID - WAS                        :     3201606009684
        /// - App ID - Tizen                      :     rJeHak5zRg.Spotify
        /// -----------------------------------------------------------------------------------------------------
        /// [14 - eManual]
        /// - App Name                            :     eManual
        /// - App Version                         :     2.1.4
        /// - App ID - WAS                        :     20202100004
        /// - App ID - Tizen                      :     OzNoIbpz56.emanual
        /// -----------------------------------------------------------------------------------------------------
        /// [15 - HBO Max]
        /// - App Name                            :     HBO Max
        /// - App Version                         :     50.16.0
        /// - App ID - WAS                        :     3201601007230
        /// - App ID - Tizen                      :     cj37Ni3qXM.HBONow
        /// -----------------------------------------------------------------------------------------------------
        /// [16 - Samsung Promotion]
        /// - App Name                            :     Samsung Promotion
        /// - App Version                         :     3.2.9
        /// - App ID - WAS                        :     3201807016658
        /// - App ID - Tizen                      :     yL49PNFmjW.PromotionApp
        /// -----------------------------------------------------------------------------------------------------
        public enum App {
            case netflix
            case appleMusic
            case appletv
            case youtube
            case primevideo
            case disneyplus
            case spotify
            case hulu
            case hbo
            var details: (appID: String, channelURI: String) {
                switch self {
                case .netflix:
                    return ("3201907018807", "org.tizen.netflixapp")
                case .appletv:
                    return ("3201807016597", "com.samsung.tv.ariavideo")
                case .appleMusic:
                    return ("3201908019041", "org.tizen.apple.applemusic")
                case .youtube:
                    return ("111299001912", "com.samsung.multiscreen.youtube")
                case .primevideo:
                    return ("3201910019365", "org.tizen.primevideo")
                case .disneyplus:
                    return ("3201901017640", "MCmYXNxgcu.DisneyPlus")
                case .spotify:
                    return ("3201606009684", "rJeHak5zRg.Spotify")
                case .hulu:
                    return ("3201601007625", "LBUAQX1exg.Hulu")
                case .hbo:
                    return ("3201601007230", "cj37Ni3qXM.HBONow")
                }
            }
        }
        
        public enum ControlType: String, Codable {
            case inputEnd = "SendInputEnd"
            case inputString = "SendInputString"
            case mouseDevice = "ProcessMouseDevice"
            case remoteKey = "SendRemoteKey"
        }

        public let position: Position?
        /// Command to be executed, e.g., "Click"
        public let cmd: String
        /// Specific key data associated with the command
        public let dataOfCmd: ControlKey?
        /// Additional option that may modify the command's execution
        public let option: Bool?
        /// Type of the remote control that the command applies to, e.g., "SendRemoteKey"
        public let typeOfRemote: ControlType

        enum CodingKeys: String, CodingKey {
            case cmd = "Cmd"
            case dataOfCmd = "DataOfCmd"
            case option = "Option"
            case typeOfRemote = "TypeOfRemote"
            case position = "Position"
        }

        public init(cmd: Command, dataOfCmd: ControlKey? = nil, option: Bool? = nil, typeOfRemote: ControlType, position: Position? = nil) {
            self.cmd = cmd.rawValue
            self.dataOfCmd = dataOfCmd
            self.option = option
            self.typeOfRemote = typeOfRemote
            self.position = position
        }

        public init(cmd: String, dataOfCmd: ControlKey, typeOfRemote: ControlType) {
            self.cmd = cmd
            self.dataOfCmd = dataOfCmd
            self.option = nil
            self.typeOfRemote = typeOfRemote
            self.position = nil
        }
    }

    /// The type of method performed via the WebSocket
    public let method: Method
    /// An object containing parameters needed to execute the command
    public let params: Params

    public init(method: Method, params: Params) {
        self.method = method
        self.params = params
    }
}

public struct TVResponse<Body: Codable>: Codable {
    public let data: Body?
    public let event: TVChannelEvent
}

public typealias TVAuthResponse = TVResponse<TVAuthResponseBody>

// TODO:  make params optional
/// Data payload associated with a TVAuthResponse
public struct TVAuthResponseBody: Codable {
    /// List of clients connected to the TV
    public let clients: [TVClient]?
    /// Identifier associated with an authorized connection
    public let id: String?
    /// New token passed back with an authorized connection
    public let token: TVAuthToken?
}

public enum TVChannelEvent: String, Codable {
    case connect = "ms.channel.connect"
    case disconnect = "ms.channel.disconnect"
    case clientConnect = "ms.channel.clientConnect"
    case clientDisconnect = "ms.channel.clientDisconnect"
    case data = "ms.channel.data"
    case error = "ms.channel.error"
    case message = "ms.channel.message"
    case ping = "ms.channel.ping"
    case ready = "ms.channel.ready"
    case timeout = "ms.channel.timeOut"
    case unauthorized = "ms.channel.unauthorized"
}

/// Represents a client connected to the TV
public struct TVClient: Codable, Identifiable {
    /// Attributes of a client connected to the TV
    public struct Attributes: Codable {
        /// Name of the client (encoded in Base64)
        public let name: String?
        /// Refreshed token associated with the client
        public let token: TVAuthToken?

        public init(name: String?, token: TVAuthToken?) {
            self.name = name
            self.token = token
        }
    }

    /// Attributes of the client
    public let attributes: Attributes
    /// Timestamp when the client connected
    public let connectTime: Int
    /// Name of the device (encoded in Base64)
    public let deviceName: String
    /// Unique identifier of the client's authorized connection
    public let id: String
    /// Indicates whether the client is the host or not
    public let isHost: Bool

    public init(attributes: Attributes, connectTime: Int, deviceName: String, id: String, isHost: Bool) {
        self.attributes = attributes
        self.connectTime = connectTime
        self.deviceName = deviceName
        self.id = id
        self.isHost = isHost
    }
}

public typealias TVKeyboardLayout = [[String]]

public struct TVWakeOnLANDevice {
    public var mac: String
    public var broadcast: String
    public var port: UInt16

    public init(mac: String, broadcast: String = "255.255.255.255", port: UInt16 = 9) {
        self.mac = mac
        self.broadcast = broadcast
        self.port = port
    }

    public init(device: TV.Device, broadcast: String = "255.255.255.255", port: UInt16 = 9) {
        self.init(mac: device.wifiMac, broadcast: broadcast, port: port)
    }
}
