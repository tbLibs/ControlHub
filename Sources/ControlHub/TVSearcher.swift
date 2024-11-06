//
//  TVSearcher.swift
//
//
//  Created by Amir Daliri.
//

import Foundation
import SmartView

public protocol TVSearching: AnyObject {
    func addSearchObserver(_ observer: any TVSearchObserving)
    func removeSearchObserver(_ observer: any TVSearchObserving)
    func removeAllSearchObservers()
    func configureTargetTVId(_ targetTVId: TV.ID?)
    func startSearch()
    func stopSearch()
}

public protocol TVSearchRemoteInterfacing: AnyObject {
    func setDelegate(_ observer: TVSearchObserving)
    func startSearch()
    func stopSearch()
}

public protocol TVSearchObserving: AnyObject {
    func tvSearchDidStart()
    func tvSearchDidStop()
    func tvSearchDidFindTV(_ tv: TV, service: Service?)
    func tvSearchDidLoseTV(_ tv: TV)
    func tvSearchDidFailToLaunchApp(_ error: TVCommanderError) // New method
}

public class TVSearcher: TVSearching, TVSearchObserving {
    private let remote: TVSearchRemoteInterfacing
    private var observers = [TVSearchObserving]()
    private var targetTVId: TV.ID?
    private var connectedService: Service?
    private var serviceSearch: ServiceSearch
    private let logger = ControlHubLogger(category: "TVCommander")

    public init(remote: TVSearchRemoteInterfacing? = nil) {
        self.remote = remote ?? TVSearchAdaptor()
        self.serviceSearch = Service.search()
        self.remote.setDelegate(self)
        logger.info("Initialized TVSearcher")
    }

    // MARK: Add / Remove Observers

    public func addSearchObserver(_ observer: any TVSearchObserving) {
        observers.append(observer)
    }

    public func removeSearchObserver(_ observer: any TVSearchObserving) {
        observers.removeAll { $0 === observer }
    }

    public func removeAllSearchObservers() {
        observers.removeAll()
    }

    // MARK: Search for TVs

    public func configureTargetTVId(_ targetTVId: TV.ID?) {
        self.targetTVId = targetTVId
    }

    public func startSearch() {
        remote.startSearch()
        logger.debug("Started TV search")
    }

    public func stopSearch() {
        remote.stopSearch()
        logger.debug("Stopped TV search")
    }

    public func tvSearchDidStart() {
        observers.forEach {
            $0.tvSearchDidStart()
        }
    }

    public func tvSearchDidStop() {
        observers.forEach {
            $0.tvSearchDidStop()
        }
    }

    public func tvSearchDidFindTV(_ tv: TV, service: Service?) {
        observers.forEach {
            $0.tvSearchDidFindTV(tv, service: service)
        }
        connectedService = service
    }

    public func tvSearchDidLoseTV(_ tv: TV) {
        observers.forEach {
            $0.tvSearchDidLoseTV(tv)
        }
    }
    
    public func tvSearchDidFailToLaunchApp(_ error: TVCommanderError) {
        observers.forEach {
            $0.tvSearchDidFailToLaunchApp(error)
        }
    }
    
    
    public func castPhoto(url: URL, fileName: String) async throws {
        if let service = connectedService {
            let player = service.createPhotoPlayer("TVRemote")
            try await player.playContent(url: url, title: fileName)
        } else {
            throw TVCommanderError.noServiceConnected
        }
    }
    
    public func castVideo(url: URL, fileName: String) async throws {
        if let service = connectedService {
            let player = service.createVideoPlayer("TVRemote")
            try await player.playContent(url: url, title: fileName)
        } else {
            throw TVCommanderError.noServiceConnected
        }
    }

    // MARK: Launch Apps
    
    public func launchApplication(app: TVRemoteCommand.Params.App) {
        launchApp(appID: app.details.appID, channelURI: app.details.channelURI)
    }
    
    private func launchApp(appID: String, channelURI: String) {
        if channelURI == "org.tizen.browser" {
            launchBrowser()
            return
        }
        
        guard let service = connectedService else {
            tvSearchDidFailToLaunchApp(TVCommanderError.noServiceConnected)
            return
        }

        guard let app = service.createApplication(appID as AnyObject, channelURI: channelURI, args: nil) else {
            tvSearchDidFailToLaunchApp(TVCommanderError.appCreationFailed)
            return
        }
        
        app.connect(nil, completionHandler: { client, error in
            if let error = error {
                self.tvSearchDidFailToLaunchApp(TVCommanderError.connectionError(error))
            } else {
                app.start { success, error in
                    if let error = error {
                        self.tvSearchDidFailToLaunchApp(TVCommanderError.launchError(error))
                    } 
                }
            }
        })
    }
    
    private func launchBrowser() {
        guard let tvService = connectedService else {
            tvSearchDidFailToLaunchApp(TVCommanderError.noServiceConnected)
            return
        }
        
        guard let browserApp = tvService.createApplication(
            "org.tizen.browser" as AnyObject,
            channelURI: "browser",
            args: nil
        ) else { return }
            
        browserApp.connect(nil) { client, error in
            if let error = error {
                self.tvSearchDidFailToLaunchApp(TVCommanderError.connectionError(error))
            } else {
                browserApp.start { _, error in
                    if let error = error {
                        self.tvSearchDidFailToLaunchApp(TVCommanderError.launchError(error))
                    }
                }
            }
        }
    }
}

class TVSearchAdaptor: TVSearchRemoteInterfacing, ServiceSearchDelegate {
    private let search: ServiceSearch
    private weak var delegate: TVSearchObserving?
    var connectedService: Service?

    init() {
        self.search = Service.search()
        self.search.delegate = self
    }

    func setDelegate(_ observer: any TVSearchObserving) {
        self.delegate = observer
    }

    func startSearch() {
        search.start()
    }

    func stopSearch() {
        search.stop()
    }

    func onStart() {
        delegate?.tvSearchDidStart()
    }

    func onStop() {
        delegate?.tvSearchDidStop()
    }

    func onServiceFound(_ service: Service) {
        delegate?.tvSearchDidFindTV(.init(service: service), service: service)
    }

    func onServiceLost(_ service: Service) {
        delegate?.tvSearchDidLoseTV(.init(service: service))
    }
}

extension TV {
    init(service: Service) {
        self.init(
            id: service.id,
            name: service.name,
            type: service.type,
            uri: service.uri
        )
    }
}
