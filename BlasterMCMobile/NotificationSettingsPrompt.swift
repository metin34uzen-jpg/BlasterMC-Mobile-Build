import SwiftUI

struct NotificationSettingsPrompt: View {
    @ObservedObject var push: PushCoordinator

    var body: some View {
        VStack(spacing: 17) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(BlasterTheme.amber)
                .frame(width: 84, height: 84)
                .background(BlasterTheme.navy, in: RoundedRectangle(cornerRadius: 25))
                .padding(.top, 10)

            Text("BlasterMC bildirimleri kapalı")
                .font(.title2.weight(.black))
                .foregroundStyle(BlasterTheme.ink)
                .multilineTextAlignment(.center)

            Text("Yeni sezonları, etkinlikleri ve önemli duyuruları kaçırmamak için iPhone Ayarlar'dan bildirimleri açabilirsin.")
                .font(.subheadline)
                .foregroundStyle(BlasterTheme.muted)
                .multilineTextAlignment(.center)

            GoldButton(title: "iPHONE AYARLARINI AÇ", symbol: "gearshape.fill") {
                push.openSystemSettings()
            }

            Button("Daha sonra") {
                push.showSettingsPrompt = false
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(BlasterTheme.muted)
            .padding(.vertical, 8)

            Text("Apple, reddedilen bildirimi yeniden sistem penceresiyle sormaya izin vermez.")
                .font(.caption2)
                .foregroundStyle(BlasterTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(27)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BlasterTheme.canvas.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
