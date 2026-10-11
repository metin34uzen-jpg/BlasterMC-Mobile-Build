import SwiftUI

@main
struct BlasterMCMobileApp: App {
    @UIApplicationDelegateAdaptor(BlasterAppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
