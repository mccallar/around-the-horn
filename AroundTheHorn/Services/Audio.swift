import AVFoundation

/// The square-wave synth (spec §10): every cue is rendered once into a PCM buffer the
/// way the prototype's `beep` shapes a note — a square (or sawtooth) wave starting at a
/// low gain and decaying exponentially to near silence — then played on a small pool of
/// player nodes so cues can overlap. The session is `.ambient`: the player's own music
/// keeps playing.
final class Synth {
    static let shared = Synth()

    struct Note {
        let hz: Double
        let seconds: Double
        var saw = false
        var volume = 0.03
        var at = 0.0
    }

    static let sampleRate = 44_100.0

    /// The prototype's cue table: beeps from `view`/`showMsg`/the shop/the harpoon, and
    /// the tunes `T_TITLE`, `T_ARRIVE`, `T_DEATH`, `T_WIN` and the catch.
    static func notes(_ cue: Cue) -> [Note] {
        switch cue {
        case .click: return [Note(hz: 520, seconds: 0.03, volume: 0.035)]
        case .message: return [Note(hz: 240, seconds: 0.07, volume: 0.035)]
        case .shopUp: return [Note(hz: 880, seconds: 0.025, volume: 0.035)]
        case .shopDown: return [Note(hz: 440, seconds: 0.025, volume: 0.035)]
        case .harpoon: return [Note(hz: 320, seconds: 0.06, saw: true, volume: 0.035)]
        case .stranger: return [Note(hz: 200, seconds: 0.15, volume: 0.035)]
        case .unmute: return [Note(hz: 660, seconds: 0.05, volume: 0.035)]
        case .title: return tune([(392, 0.15), (523, 0.15), (659, 0.15), (784, 0.3), (659, 0.15), (698, 0.15),
                                  (784, 0.15), (880, 0.45), (784, 0.15), (659, 0.15), (523, 0.4)])
        case .arrive: return tune([(523, 0.1), (659, 0.1), (784, 0.1), (1047, 0.25)])
        case .death: return tune([(392, 0.3), (349, 0.3), (311, 0.3), (262, 0.7)])
        case .win: return tune([(523, 0.12), (523, 0.12), (659, 0.12), (784, 0.24), (659, 0.12), (784, 0.12), (1047, 0.5)])
        case .fishHit: return tune([(660, 0.06), (880, 0.1)])
        }
    }

    /// The prototype's `tune`: notes back to back, each 95% of its slot.
    static func tune(_ seq: [(Double, Double)]) -> [Note] {
        var t = 0.0
        return seq.map { hz, d in
            defer { t += d }
            return Note(hz: hz, seconds: d * 0.95, at: t)
        }
    }

    /// Mono float samples for a cue.
    static func render(_ notes: [Note]) -> [Float] {
        let end = notes.map { $0.at + $0.seconds + 0.03 }.max() ?? 0
        var out = [Float](repeating: 0, count: Int(end * sampleRate))
        for n in notes {
            let start = Int(n.at * sampleRate)
            let count = Int((n.seconds + 0.03) * sampleRate)
            for i in 0..<count where start + i < out.count {
                let tau = Double(i) / sampleRate
                // exponentialRampToValueAtTime(0.0001, t + d), then hold until stop.
                let gain = n.volume * pow(0.0001 / n.volume, min(tau, n.seconds) / n.seconds)
                let phase = (tau * n.hz).truncatingRemainder(dividingBy: 1)
                let wave = n.saw ? 2 * phase - 1 : (phase < 0.5 ? 1 : -1)
                out[start + i] += Float(gain * wave)
            }
        }
        return out
    }

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var next = 0
    private var buffers: [Cue: AVAudioPCMBuffer] = [:]
    private let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    private var started = false

    private func start() -> Bool {
        if started { return true }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            for _ in 0..<4 {
                let p = AVAudioPlayerNode()
                engine.attach(p)
                engine.connect(p, to: engine.mainMixerNode, format: format)
                players.append(p)
            }
            try engine.start()
            started = true
        } catch {
            print("audio unavailable: \(error)")
        }
        return started
    }

    private func buffer(_ cue: Cue) -> AVAudioPCMBuffer? {
        if let b = buffers[cue] { return b }
        let samples = Self.render(Self.notes(cue))
        guard let b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return nil }
        b.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { b.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
        buffers[cue] = b
        return b
    }

    func play(_ cue: Cue) {
        guard start(), let b = buffer(cue) else { return }
        if !engine.isRunning { try? engine.start() }
        let p = players[next]
        next = (next + 1) % players.count
        p.stop()
        p.scheduleBuffer(b, at: nil, options: .interrupts)
        p.play()
    }
}
