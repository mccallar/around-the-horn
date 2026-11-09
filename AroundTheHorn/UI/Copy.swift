import HornEngine

// Screen text the engine doesn't own, copied from the prototype's screen functions of
// the same names (spec §6). Markup per spec §13.

enum Copy {
    static let learn: [(heading: String, paragraphs: [String])] = [
        ("The voyage", [
            "In 1849, news of gold in California emptied the seaports of the East. One road west went overland. The other went by sea — fourteen thousand miles south through the Atlantic, around the stormy tip of South America, and north up the Pacific.",
            "You are captain of a small ship with a crew of five. You must buy supplies, keep your crew alive, keep your ship afloat, and reach San Francisco.",
        ]),
        ("Supplies", [
            "[amber]Provisions[/amber] and [amber]water[/amber] run out fast. Restock at ports — at a price.",
            "[amber]Citrus[/amber] prevents scurvy. After a month without it, your crew will start to sicken.",
            "[amber]Woolens[/amber] keep sailors alive in the far south — one set per person.",
            "[amber]Sailcloth[/amber] and [amber]timber[/amber] repair your ship at sea. [amber]Tackle[/amber] lets you fish for food.",
        ]),
        ("The Horn", [
            "Off Tierra del Fuego you must choose: round [amber]Cape Horn[/amber] in open ocean, or thread the narrow, rocky [amber]Strait of Magellan[/amber].",
            "Timing matters. From May to September it is winter down there, and the seas are the worst on earth. Leave New York too late and you will pay for it.",
            "Pace and rations matter too: pushing hard gets you there faster, if anyone survives.",
        ]),
    ]

    static let titleTagline = "Fourteen thousand miles from New York to the gold fields of California, by sea."

    static let roleIntro = "Many kinds of people made the voyage in 1849. You may:"

    static let roleDifferences = [
        "Passage to California was expensive, and not everyone who went was rich.",
        "[amber]Merchant[/amber] — starts with $1,500.",
        "[amber]Shipwright[/amber] — starts with $850. Gets far more out of every bolt of sailcloth and bundle of timber.",
        "[amber]Whaler[/amber] — starts with $500. Deadly with a harpoon and can salt a bigger catch.",
        "The poorer you start, the more your arrival is worth: the shipwright scores double, the whaler triple.",
    ]

    static let monthIntro = "The news from California reached New York in December 1848. Ships are leaving every day. When will you weigh anchor?"

    static let monthAdvice = "An old shipmaster scratches his beard: “Leave too early and the North Atlantic winter will batter you before you reach the trades. Leave too late and you will reach the Horn in the southern winter — and God help you then. December or January, if you can.”"

    static func outfitIntro(money: Double, ship: String) -> String {
        "You have [amber]$\(formatNumber(money))[/amber] to fit out the [i]\(ship)[/i]. The chandler on South Street has what you need:"
    }

    static let outfitBullets = [
        "• [b]Provisions[/b] — five people eating well use 15 lbs a day. The voyage may take five months. Ports sell more, at a markup.",
        "• [b]Water[/b] — about a gallon per person per day. Rain can be caught in the sails.",
        "• [b]Citrus[/b] — without it, scurvy sets in after a month.",
        "• [b]Oilskins & woolens[/b] — one set per person, or the cold will kill them.",
        "• [b]Sailcloth & timber[/b] — the only way to make repairs at sea.",
        "• [b]Medicine & fishing tackle[/b].",
    ]

    static let rankLegend = "Master Mariner 7,000+ · Able Seaman 4,000+ · Ordinary Seaman 2,000+ · Greenhand"
}
