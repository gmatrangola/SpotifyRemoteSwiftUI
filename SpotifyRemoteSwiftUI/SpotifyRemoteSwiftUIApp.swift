//
//  SpotifyRemoteSwiftUIApp.swift
//  SpotifyRemoteSwiftUI
//
//  Created by Geoffrey Matrangola on 2/4/23.
//

import SwiftUI

@main
struct SpotifyRemoteSwiftUIApp: App {
    @StateObject var sptConnector = SPTConnector()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sptConnector)
                .onOpenURL { url in
                    print("onOpenURL \(url.description)")
                    sptConnector.setResponseCode(from: url)
                }
        }
    }
}
