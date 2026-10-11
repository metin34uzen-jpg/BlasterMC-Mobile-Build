import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var session = BlasterSession()
    @StateObject private var server = ServerStatusModel()
    @StateObject private var push = PushCoordinator.shared
    @State private var tab = 0
    @State private var showingIntro = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if showingIntro {
                IntroScreen()
                    .transition(.opacity)
            } else if !session.isSignedIn {
                LoginPortal()
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
        .sheet(isPresented: $push.showSettingsPrompt) {
            NotificationSettingsPrompt(push: push)
        }
        .onChange(of: session.isSignedIn) { oldValue, newValue in
            if !oldValue && newValue {
                Task { await push.checkAfterLogin() }
            }
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
        TabView(selection: $tab) {
            HomeView(server: server, navigate: { tab = $0 }, isSelected: tab == 0)
                .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
                .tag(0)
            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.square") }
                .tag(1)
            StoreView()
                .tabItem { Label("Mağaza", systemImage: "bag.fill") }
                .tag(2)
            SeasonView()
                .tabItem { Label("Sezon", systemImage: "trophy.fill") }
                .tag(3)
            NewsView()
                .tabItem { Label("Haberler", systemImage: "bell.fill") }
                .tag(4)
        }
        .tint(BlasterTheme.gold)
    }
}
