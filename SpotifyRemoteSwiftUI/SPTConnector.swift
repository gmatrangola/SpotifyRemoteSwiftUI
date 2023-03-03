//
//  SPTConnector.swift
//  SpotifyRemoteSwiftUI
//
//  Created by Geoffrey Matrangola on 2/12/23.
//

import SwiftUI

class SPTConnector: NSObject, ObservableObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate, SPTSessionManagerDelegate {
    @Published var isConntected: Bool = false
    @Published var isAuthorized: Bool = false;
    @Published var playerSteate: SPTAppRemotePlayerState? = nil
    @Published var artwork: UIImage? = nil
    @Published var error: Error? = nil
    @Published var sptSession: SPTSession? = nil
    private var lastPlayerState: SPTAppRemotePlayerState?

    // MARK: - Spotify Authorization & Configuration
    var responseCode: String? {
        didSet {
            print("responseCode didSet")
            fetchAccessToken { (dictionary, error) in
                if let error = error {
                    print("Fetching token request error \(error)")
                    self.error = error
                    return
                }
                let accessToken = dictionary!["access_token"] as! String
                DispatchQueue.main.async {
                    print("responseCode didSet appRemote")
                    self.appRemote.connectionParameters.accessToken = accessToken
                    self.appRemote.connect()
                }
            }
        }
    }
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        print("appRemote \(appRemote.description)")
        return appRemote
    }()
    
    func setAccessToken(from url: URL) {
        let parameters = appRemote.authorizationParameters(from: url)
        print("setAccessToken")
        if let accessToken = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = accessToken
            self.accessToken = accessToken
        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print(errorDescription)
        }
    }
    
    var accessToken = UserDefaults.standard.string(forKey: accessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: accessTokenKey)
        }
    }
    
    func setResponseCode(from url: URL) {
        let parameters = self.appRemote.authorizationParameters(from: url)
        if let code = parameters?["code"] {
            self.responseCode = code
        } else if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            self.accessToken = access_token
        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("No access token error =", error_description)
        }
    }
    
    lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: spotifyClientId, redirectURL: redirectUri)
        // Set the playURI to a non-nil value so that Spotify plays music after authenticating
        // otherwise another app switch will be required
        configuration.playURI = ""
        // Set these url's to your backend which contains the secret to exchange for an access token
        // You can use the provided ruby script spotify_token_swap.rb for testing purposes
        configuration.tokenSwapURL = URL(string: "http://localhost:1234/swap")
        configuration.tokenRefreshURL = URL(string: "http://localhost:1234/refresh")
        return configuration
    }()
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        isConntected = true
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
                self.error = error
            }
        })
        print("appRemoteDidEstablishConnection")
        fetchPlayerState()
    }
    
    // MARK: - Session Manager
    lazy var sessionManager: SPTSessionManager? = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        print("sessionManager \(manager.description)")
        return manager
    }()
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        if error.localizedDescription == "The operation couldn’t be completed. (com.spotify.sdk.login error 1.)" {
            print("AUTHENTICATE with WEBAPI")
        } else {
            isAuthorized = false
            print(error.localizedDescription)
            self.error = error
        }
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("Session Renewed \(session.description)")
        self.sptSession = session
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("sessionManager didInitiate \(session.description)")
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
    }

    func initiateSession() {
        print("initiateSession() start")
        guard let sessionManager = sessionManager else { return }
        sessionManager.initiateSession(with: scopes, options: .clientOnly)
        print("initiateSession() called")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Could not connetect \(String(describing: error))")
        self.error = error
        self.isConntected = false
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Connection Lost \(String(describing: error))")
        isConntected = false
        self.error = error
        playerSteate = nil
        artwork = nil
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("playerStateDidChange()")
        lastPlayerState = self.playerSteate
        self.playerSteate = playerState
        if (lastPlayerState == nil || lastPlayerState?.track.uri != playerState.track.uri) {
            fetchArtwork(for: playerState.track)
        }
    }
    
    // MARK: - Networking
    func fetchAccessToken(completion: @escaping ([String: Any]?, Error?) -> Void) {
        print("fetchAccessToken")
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let spotifyAuthKey = "Basic \((spotifyClientId + ":" + spotifyClientSecretKey).data(using: .utf8)!.base64EncodedString())"
        request.allHTTPHeaderFields = ["Authorization": spotifyAuthKey,
                                       "Content-Type": "application/x-www-form-urlencoded"]

        var requestBodyComponents = URLComponents()
        let scopeAsString = stringScopes.joined(separator: " ")

        requestBodyComponents.queryItems = [
            URLQueryItem(name: "client_id", value: spotifyClientId),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: responseCode!),
            URLQueryItem(name: "redirect_uri", value: redirectUri.absoluteString),
            URLQueryItem(name: "code_verifier", value: ""), // not currently used
            URLQueryItem(name: "scope", value: scopeAsString),
        ]

        request.httpBody = requestBodyComponents.query?.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,                              // is there data
                  let response = response as? HTTPURLResponse,  // is there HTTP response
                  (200 ..< 300) ~= response.statusCode,         // is statusCode 2XX
                  error == nil else {                           // was there no error, otherwise ...
                      print("Error fetching token \(error?.localizedDescription ?? "")")
                      return completion(nil, error)
                  }
            let responseObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("Access Token Dictionary=", responseObject ?? "")
            completion(responseObject, nil)
        }
        task.resume()
    }

    func fetchArtwork(for track: SPTAppRemoteTrack) {
        appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize.zero, callback: { [weak self] (image, error) in
            if let error = error {
                print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage {
                self?.artwork = image
            }
        })
    }

    func fetchPlayerState() {
        print("fetchPlayerState()")
        appRemote.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                print("Error getting player state:" + error.localizedDescription)
                self?.error = error
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.playerSteate = playerState
                print("got player state \(playerState.description)")
            }
        })
    }

}
