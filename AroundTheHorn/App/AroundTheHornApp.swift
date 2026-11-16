import SwiftUI

@main
struct AroundTheHornApp: App {
    @State private var controller: GameController = {
        // `-journey <id>` goes straight to that journey's title card.
        let c = GameController(journey: UserDefaults.standard.string(forKey: "journey"))
        // `-HornTickSeconds 4` slows the voyage clock for UI tests, which can't query a
        // screen that redraws every 0.7 s.
        let s = UserDefaults.standard.double(forKey: "HornTickSeconds")
        if s > 0 { c.tickInterval = .milliseconds(Int(s * 1000)) }
        Feedback.play = { [weak c] cue in
            guard let c, !c.muted else { return }
            Synth.shared.play(cue)
        }
        #if DEBUG
        if let stop = UserDefaults.standard.string(forKey: "HornDebugStart") {
            func number(_ key: String) -> Double? {
                UserDefaults.standard.object(forKey: key) == nil ? nil : UserDefaults.standard.double(forKey: key)
            }
            c.debugStart(at: stop, month: UserDefaults.standard.integer(forKey: "HornDebugMonth"),
                         atStop: UserDefaults.standard.bool(forKey: "HornDebugAtStop"), hull: number("HornDebugHull"),
                         fuel: number("HornDebugFuel"))
        }
        #endif
        return c
    }()
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
