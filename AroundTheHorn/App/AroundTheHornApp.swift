import SwiftUI

@main
struct AroundTheHornApp: App {
    @State private var controller = GameController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(controller)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in controller.scenePhaseChanged(phase) }
        }
    }
}
