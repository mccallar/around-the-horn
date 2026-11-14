import Foundation

// The six fields where a ground team waits with propane, helium and supplies. Propane is
// cheapest at Luxor of every field after Marrakech; burner parts at Albuquerque; ballast at
// Jodhpur, where the Thar has sand to spare.

extension Balloon {
    static let fields: [Port] = [
        Port(id: "mar", journey: Balloon.id, name: "Marrakech", shop: "The supply hangar at the launch field", mult: 1,
             arrive: "",
             talk: [
                "A rigger coiling a load tape: \"Every team that's tried this came down early. The ones that planned for the cold came down later. Buy the down suits.\"",
                "Your meteorologist, pinning a chart to the tent wall: \"December to February, the jet is a river. In November it hasn't filled, and by March it's a creek. Don't be on it in March.\"",
                "A retired airline captain who has come out to watch: \"Scrubbers. Everybody forgets the scrubbers. Five people in a sealed can make a great deal of bad air.\"",
             ]),
        Port(id: "lux", journey: Balloon.id, name: "Luxor", shop: "A balloon outfitter on the West Bank", mult: 1.3,
             mods: [.fuel: 0.8, .water: 0.7, .clothes: 1.4, .sailcloth: 1.3],
             arrive: "You come down on the West Bank, on the dusty field where the little tourist balloons land every morning, with the temples on one side and the Nile on the other. Half the village walks out to watch you land.",
             talk: [
                "A tourist-balloon pilot: \"We fly one hour every morning and call ourselves brave. Mind the haze over the Red Sea — it's thick as soup.\"",
                "Your ground-team driver, beating dust off his cap: \"Propane's cheaper here than at any field ahead of you. Fill every tank you've got.\"",
                "A guide in a white robe: \"People have watched the sky over this valley for four thousand years. You are the first I have seen arrive from Morocco.\"",
             ]),
        Port(id: "jod", journey: Balloon.id, name: "Jodhpur", shop: "A gas depot by the old airfield", mult: 1.35,
             mods: [.food: 0.7, .water: 0.8, .fuel: 1.1, .sailcloth: 1.4, .timber: 0.4],
             arrive: "You land on a dry plain below the great fort, in a cloud of red dust. Half the city comes out to watch, and somebody brings tea.",
             talk: [
                "A schoolteacher: \"Beyond us, the Himalaya. Beyond them, China, and then the sea. There is a great deal of 'beyond' in your plans.\"",
                "Your ground-team chief: \"Sand for ballast is the one thing the Thar has plenty of. Buy all you can lift.\"",
                "A mechanic from the airfield: \"Your burners will ice up over the mountains. Carry spares, and somebody who can fit them wearing gloves.\"",
             ]),
        Port(id: "saga", journey: Balloon.id, name: "Saga", shop: "The fiesta grounds by the Kase River", mult: 1.6,
             mods: [.sailcloth: 0.8, .food: 1.2, .limes: 0.9], fever: true,
             arrive: "You come down on the wide gravel bed of the Kase River, where the city holds its balloon fiesta every autumn. A crowd is already lining the bank, waving paper flags.",
             talk: [
                "A fiesta organiser: \"From here the jet runs straight out over the ocean, faster than any ship. The next land is America. There is nothing in between.\"",
                "A balloon maker: \"Last winter a team left here with half-full tanks. A fishing boat found them near Midway, sitting on their capsule. Fill your tanks.\"",
                "A doctor at the field: \"The winter flu is everywhere this month. Wash your hands, and don't linger.\"",
             ]),
        Port(id: "abq", journey: Balloon.id, name: "Albuquerque", shop: "A balloon works on the north side of town", mult: 1.25,
             mods: [.sailcloth: 0.6, .timber: 0.7, .fuel: 0.9],
             arrive: "You land on the great dusty field where the city holds its balloon fiesta. A dozen local pilots are waiting for you, and every one of them has advice.",
             talk: [
                "An old balloonist in a feed-store cap: \"Three fellows from this town were the first to fly the Atlantic in a balloon, back in '78. You're carrying their luck. Don't waste it.\"",
                "A burner mechanic: \"Best burner parts in the country, and the cheapest. Stock up. The Atlantic doesn't sell spares.\"",
                "A television reporter: \"The whole country's watching. Can you say something about the Pacific? Anything. Thirty seconds.\"",
             ]),
        Port(id: "kh", journey: Balloon.id, name: "Kitty Hawk", shop: "The hangar beside the Wright memorial", mult: 1.45,
             mods: [.fuel: 1.1, .clothes: 0.9], fever: true,
             arrive: "You come down on the little airstrip beside the Wright Brothers memorial, its granite pylon standing on top of its dune. The wind whips sand across the runway.",
             talk: [
                "A park ranger: \"The first airplane flew from the flat sand below that hill in 1903, for twelve seconds. You've been up for weeks. Mind the difference.\"",
                "Your ground-team chief: \"From here it's the Atlantic and nothing else. No more fields, no more trucks. Whatever you'll need, buy it now.\"",
                "A fisherman on the beach road: \"There's flu all down the Outer Banks this winter. Keep away from the crowd.\"",
             ]),
    ]
}
