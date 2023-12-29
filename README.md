# SpotifyRemoteSwiftUI

This is an alternative implementation of the Sample Spotify iOS app https://github.com/spotify/ios-sdk using [SwiftUI](https://developer.apple.com/Xcode/swiftui/) instead of [UIKit](https://developer.apple.com/documentation/uikit).
It is very basic interface to the Spotify App running on your phone for learning and demonstartion purposes. A real app would probably do a lot of these interactions in the background.

The demonstrates some basic features of the SpotifyiOS.framework. This is how to use it once you get it running on your iPhone. This is a little bit jiggy the first time you connect, because it has to authenticate your Spotify Account through the Spotify App. But then you need to re-connect to the Spotify app
after timeout, but you won't need to reauthenticate.
- Press connect to the Spotify iOS app to authenticate.
- Allow the app to access your Spotify Account
- The app will launch the Spotify App and resume playing the last song/playlist/album
- The SpotifyiOS.framework will return control to SpotifyRemoteSwiftUI
- SpotifyRemoteSwiftUI will query the SpotifyiOS.framework to determine the play/pause state and current album art.
- When the SpotifyiOS.framework responds with the playing state SpotifyRemoteSwiftUI updates the @Published attributes including the play/pause state and requests the album artwork. 
- The changes to the @Published attributes cause the play/pause icon to appear in ContentView.swift.
- The album art is eventually presented to SPTConnector, @Published artwork is updated and it then it is displayed in the ContentView.swift.
- If you hit the Pause button, eventually the Spotify App goes into the iOS Frozen state in order to save batter etc. This will cause then cause the disconnect app to be sent though the SpotifyiOS.framework causing the @Published attributes to update and, in turn, the ContentView will be updated allowing you to reconnect.


## Requirements

- Spotify Account
- Spotify App installed on your iPhone
- XCode
- A Spotify Developer's account and setting up an app in the [Spotify Dashboard](https://developer.spotify.com/dashboard/applications)
- An iPhone. This will *not* run in the simulator because it needs to talk to the Spotify App which (AFAICT) can't be installed in the simulator.

## Setup

- Clone or download this project from GitHub.com
- Launch XCode and open the project
- Put the SpotifyiOS.framework file under SpotifyRemoteSwiftUI directory in the Xcode project
- Open the [Spotify Dashboard](https://developer.spotify.com/dashboard/applications) and click Create an App.
    - Click Edit Settings
    - add sptremote://oauth/callback to the Redirect URIs (needs to be unique for each Spotify App you create) *Note this changed since the last update*
    - add the Bundle ID com.matrangola.SpotifyRemoteSwiftUI (you can change both in the source and on the dashboard if you wish)
    - hit Save 
- Edit Constants.swift and change the following lines to match the values in the Spotify Dashboard

```swift
let spotifyClientId = ""
let spotifyClientSecretKey = ""
```

## Additional Info

This is a vary basic implementation. If you want to proceed you my find these resources helpful:

- [SpotifyQuickStart](https://github.com/tillhainbach/SpotifyQuickStart)
- [Spotify iOS SDK](https://developer.spotify.com/documentation/ios/)
- [Spotify iOS SDK on GitHub](https://github.com/spotify/ios-sdk)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- Replacing AppDelegate Methods by subscribing to [NotificationCenter](https://developer.apple.com/documentation/foundation/notificationcenter)

## LICENSE

[MIT](./LICENSE) for all files excluding the `SpotifyiOS.framework`.

> **Please Note**: By using Spotify developer tools you accept their [Developer Terms of Use](https://developer.spotify.com/terms/).

## Disclaimers
- There is a lot of print messages in there that may be helpful in learning the lifecycle of the SpotifyiOS.framework. But you'll probably want to remove them if you use any of this in production work. *Especially the code that prints the result of the access tokens etc*
- I pulled all the logic interfacing with the SpotifyiOS.framework into SBTConnector.swift. I'm new to SwiftUI so I'm not quite sure this is the right naming convention.
- The key things that tripped me up for a little bit was figuring out how to handle the stuff that was done in SpotifyRemote's SceneDelegate.swift but in a UIKit way. I eventually discovered the SpotifyRemoteSwiftUIApp.swift file, and figured how to use the onOpenURL() and environmentObject() modifiers. The onOpenURL() tells the app how to handle the callbacks from authentication and the environmentObject() passes the SPTConnector object to the view. So I think all the Spotify specific interface code is isolated SPTConnector.swift, except for the onOpenURL() code.
