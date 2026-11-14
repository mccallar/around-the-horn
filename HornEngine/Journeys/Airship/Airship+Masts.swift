import Foundation

// The five mooring masts: where she can be fed, gassed, mended and gossiped about.

extension Airship {
    /// Petrol is cheap in England and dearer every mast north; furs are the other way round.
    static let masts: [Port] = [
        Port(id: "rome", journey: Airship.id, name: "Rome", shop: "The stores at the Ciampino airship works", mult: 1,
             arrive: "",
             talk: [
                "A rigger coiling a trail rope: “Every kilo you carry is a kilo the gas has to lift. Buy what you need, not what you fancy. But buy the fur suits. Whatever you think the cold is like up there, it's worse.”",
                "An old balloonist on a bench outside the shed: “Leave in May. Before that the Arctic is iron-hard; after June the fog comes down on the ice and stays there. In May the sun never sets up north and you can see where you're going.”",
                "The works doctor: “Coffee, Captain. Strong, hot, and every watch. Men who haven't slept in two days start making mistakes, and in an airship a mistake is a long way down.”",
             ]),
        Port(id: "pulham", journey: Airship.id, name: "Pulham", shop: "The air station stores at Pulham", mult: 1.2,
             mods: [.fuel: 0.9, .clothes: 1.5, .limes: 1.4],
             arrive: "Two enormous sheds rise out of the flat Norfolk fields, and beside them stands a steel mast as tall as a church spire. A ground crew of two hundred men runs out across the grass to catch your ropes.",
             talk: [
                "A ground-crew sergeant: “Petrol we've got, and cheap. Coffee you'll pay through the nose for. This is tea country, Captain.”",
                "A navigator from the station: “Over the North Sea the wind backs and freshens without warning. Watch your drift, and don't trust the coast of Norway to be where the chart says until you can see it.”",
                "A rigger at the mast head: “Mind your gas when the sun's on her. She warms up, the gas swells, the valves let it go — and come evening you're heavy and wondering where it went.”",
             ]),
        Port(id: "oslo", journey: Airship.id, name: "Oslo", shop: "A ship chandler below Ekeberg hill", mult: 1.3,
             mods: [.clothes: 0.8],
             arrive: "Half the city has climbed Ekeberg hill to see you. The mast stands on the heights above the fjord, and when the ship swings to the wind, the whole crowd sways with her.",
             talk: [
                "A ski-maker in the crowd: “Buy your furs here, not in England. We have winter eight months of the year. We know what keeps a person warm.”",
                "An old ice-pilot: “North of the Circle the fog lies on the sea like wool on a sheep. You'll fly blind for hours. Trust your compass and your clock, and nothing else.”",
                "A newspaperman: “Every paper in Europe wants your story. Wire it to us first and we'll pay you. Wire it to the others and we'll print it anyway.”",
             ]),
        Port(id: "vadso", journey: Airship.id, name: "Vadsø", shop: "The general store at Vadsø", mult: 1.45,
             mods: [.clothes: 0.7, .food: 0.9, .fuel: 1.1],
             arrive: "Vadsø is a fishing town of wooden houses on the Varanger Fjord, almost at the top of Norway. The mast stands alone on a bare island across the harbour, and the gulls have already claimed it.",
             talk: [
                "The storekeeper: “Fill every tank you have. Petrol at Kings Bay comes by ship, and they charge you for the voyage.”",
                "A reindeer herder selling skins: “Reindeer hide. The hairs are hollow — the cold can't get through. Your city wool is for summer.”",
                "A fisherman mending nets: “Out over the Barents Sea the weather turns in an hour. If you see fog coming, climb over it — or be ready to wear it as ice.”",
             ]),
        Port(id: "kingsbay", journey: Airship.id, name: "Kings Bay", shop: "The mining company store at Kings Bay", mult: 1.7,
             mods: [.fuel: 1.1, .timber: 0.8], fever: true,
             arrive: "A coal-mining settlement at the edge of the world: a pier, a few dozen huts, a mountain of coal, and a hangar of timber and canvas thirty metres high. Ice still fills half the fjord. Beyond the glaciers there is nothing but the pack, all the way to Alaska.",
             talk: [
                "A mechanic from an aeroplane party: “We'll fly to the Pole and back before your engines are warm. Of course, we have to come back. You don't.”",
                "The camp doctor: “There's influenza in the bunkhouses. Don't let your crew sleep ashore any longer than they have to.”",
                "The mast foreman: “Last mast between here and anywhere. Whatever you leave here, you'll do without. Whatever you take, you'll have to lift.”",
             ]),
    ]
}
