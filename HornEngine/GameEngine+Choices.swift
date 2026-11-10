import Foundation

// Arrivals and choices every journey shares: reaching a stop, going ashore, a trader's
// offer, and the plumbing that routes an answer back to the journey that asked.

extension GameEngine {
    // MARK: - Arrivals

    /// Called when the controller reaches an `.arrival` interrupt.
    public func beginArrival(_ stopID: String) -> [Interrupt] {
        guard let s = journey.stop(stopID) else { return [] }
        state.note = ""
        return journey.arrive(self, s)
    }

    /// Reaching a port. Its side effects happen here, before the player chooses: the
    /// trade count resets and anyone only aboard this far goes ashore.
    func portArrival(_ s: Stop) -> [Interrupt] {
        state.tradesLeft = journey.rules.portTrades
        state.talkIndex = 0
        let leaving = state.crew.filter { $0.alive && $0.leaveAt == s.id }
        state.crew.removeAll { $0.alive && $0.leaveAt == s.id }
        var detail = journey.port(s.id)?.arrive ?? ""
        for p in leaving { detail += "\n\n[dim]\(journey.text.wavesGoodbye(TextMarkup.escape(p.name)))[/dim]" }
        return [.choice(portChoice(s, detail: detail))]
    }

    func portChoice(_ s: Stop, detail: String) -> ChoiceEvent {
        ChoiceEvent(kind: .portArrival(stopID: s.id), prompt: journey.text.reached(s, state), detail: detail,
                    options: [.init(journey.text.goAshore), .init(journey.text.passBy)])
    }

    /// The journey is over and scored.
    public func finish() -> Score {
        state.over = true
        state.atPort = true
        state.weather = journey.fairWeather
        return journey.score(state)
    }

    // MARK: - Choices

    func tradeChoice(_ o: Offer, intro: String) -> ChoiceEvent {
        let t = journey.text
        return ChoiceEvent(kind: .tradeOffer(o, intro: intro),
                           prompt: t.tradeOffer(intro, journey.describe(o.give, Double(o.giveAmount)),
                                                journey.describe(o.want, Double(o.wantAmount))),
                           detail: t.tradeHave(journey.describe(o.want, state[o.want].rounded(.down))),
                           options: [.init(t.tradeAccept), .init(t.tradeDecline)])
    }

    /// A choice of the journey's own. The answer comes back to `Journey.resolve` with the
    /// same `key` and `args`.
    func ask(_ key: String, _ args: [String] = [], prompt: String, detail: String? = nil,
             options: [ChoiceEvent.Option]) -> Interrupt {
        .choice(ChoiceEvent(kind: .custom(key: key, args: args), prompt: prompt, detail: detail, options: options))
    }

    /// The player picked option `option` (0-based). Returns what follows. A disabled or
    /// out-of-range option changes nothing and returns the same choice.
    public func resolve(_ event: ChoiceEvent, option: Int) -> [Interrupt] {
        guard event.options.indices.contains(option), event.options[option].enabled else { return [.choice(event)] }
        switch event.kind {
        case .portArrival:
            if option == 0 {
                state.atPort = true
                return [.enterPort]
            }
            return []
        case .tradeOffer(let o, _):
            if option == 0 {
                applyTrade(o)
                return [.message(journey.text.tradeDone)]
            }
            return []
        case .custom(let key, let args):
            return journey.resolve(self, key, args, option)
        default:
            return journey.resolveNamed(self, event, option)
        }
    }

    // MARK: - Events

    /// One of `all` whose condition holds, by weight. Nothing happens, and no number is
    /// drawn, when none does.
    func runEvent(_ all: [JourneyEvent], _ q: inout [Interrupt]) {
        let eligible = all.filter(\.ok)
        if eligible.isEmpty { return }
        let i = weightedPick(eligible.enumerated().map { ($0.offset, $0.element.weight) })
        eligible[i].run(self, &q)
    }
}
