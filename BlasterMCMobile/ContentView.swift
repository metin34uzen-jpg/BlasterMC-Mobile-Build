import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var session = BlasterSession()
    @StateObject private var server = ServerStatusModel()
    @StateObject private var push = PushCoordinator.shared
    @State private var showingIntro = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if showingIntro {
                StudioSplash()
                    .transition(.opacity)
            } else if !session.isSignedIn {
                StudioLoginView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                mainTabs
                    .transition(.opacity)
            }
        }
        .environmentObject(session)
        .animation(.easeInOut(duration: 0.38), value: showingIntro)
        .animation(.easeInOut(duration: 0.30), value: session.isSignedIn)
        .task {
            let account = Task { await session.restore() }
            Task { await server.refresh() }
            try? await Task.sleep(for: .seconds(1))
            // Never wait for a slow network request on the splash screen.
            withAnimation { showingIntro = false }
            // Permission is requested automatically on first launch, never behind a button.
            await push.requestOnLaunch()
            await account.value
            if let token = push.deviceToken { await session.registerPushToken(token) }
        }
        .onChange(of: push.deviceToken) { _, token in
            guard let token else { return }
            Task { await session.registerPushToken(token) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                _ = session.expireIfNeeded()
                Task { await push.refreshPermissionStatus() }
            }
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            _ = session.expireIfNeeded()
        }
    }

    private var mainTabs: some View {
        ForgeShell(server: server)
    }
}
