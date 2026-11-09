import SwiftUI

/// Placeholder until M3 (spec §12), when this switches on `GameController.screen`.
struct RootView: View {
    var body: some View {
        ZStack {
            Color(red: 0x0A / 255, green: 0x0E / 255, blue: 0x14 / 255)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Text(AppInfo.displayName.uppercased())
                    .font(.system(.title2, design: .monospaced).bold())
                    .foregroundStyle(Color(red: 0xF2 / 255, green: 0xB6 / 255, blue: 0x32 / 255))
                Text("1849")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color(red: 0xEC / 255, green: 0xE4 / 255, blue: 0xCF / 255))
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("title")
        }
    }
}
