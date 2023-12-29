//
//  ContentView.swift
//  SpotifyRemoteSwiftUI
//
//  Created by Geoffrey Matrangola on 2/4/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sptConnector: SPTConnector
    private var lastPlayerState: SPTAppRemotePlayerState?
    
    var body: some View {
        VStack {
            if let img = sptConnector.artwork {
                Image(uiImage: img)
                    .resizable()
            }
            else {
                Image(systemName: "music.note")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
            }
                        
            if let playerState = sptConnector.playerSteate {
                Button {
                    if (playerState.isPaused) {
                        sptConnector.appRemote.playerAPI?.resume(nil)
                    }
                    else {
                        sptConnector.appRemote.playerAPI?.pause(nil)
                    }
                } label: {
                    Image(systemName: playerState.isPaused ? "play.rectangle.fill":"pause.rectangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
            }
            Button {
                if (sptConnector.isConntected) {
                    sptConnector.appRemote.disconnect()
                }
                else {
                    sptConnector.initiateSession()
                }
            } label: {
                Text(sptConnector.isConntected ? "Disconnect":"Connect")
            }
            .controlSize(.large)

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SPTConnector())
    }
}
