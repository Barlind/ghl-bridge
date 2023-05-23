import CoreGraphics
import ArgumentParser

struct Map: Codable {
    let buttonMask: Int
    let keyCode: CGKeyCode
    let name: String
}

struct KeyMap: Codable {
    var frets: [Map] = []
    var buttons: [Map] = []
    var strum: [Map] = []
}

let defaultKeyMap = KeyMap.init(
    frets: [
        Map(buttonMask: 0x02, keyCode: 0x12, name: "B1"), // -> '1'
        Map(buttonMask: 0x04, keyCode: 0x13, name: "B2"), // -> '2'
        Map(buttonMask: 0x08, keyCode: 0x14, name: "B3"), // -> '3'
        Map(buttonMask: 0x01, keyCode: 0x15, name: "W1"), // -> '4'
        Map(buttonMask: 0x10, keyCode: 0x17, name: "W2"), // -> '5'
        Map(buttonMask: 0x20, keyCode: 0x16, name: "W3")  // -> '6'
    ],
    buttons: [
        Map(buttonMask: 0x02, keyCode: 0x2F, name: "GHTV"), // -> '.'
        Map(buttonMask: 0x04, keyCode: 0x24, name: "Pause"), // -> 'Return'
        Map(buttonMask: 0x08, keyCode: 0x01, name: "Star Power") // -> 'S'
    ],
    strum: [
        Map(buttonMask: 0x00, keyCode: 0x00, name: "Strum UP"), // -> 'A'
        Map(buttonMask: 0xff, keyCode: 0x0B, name: "Strum Down") // -> 'B'
    ])

struct Runner: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "ghl-bridge",
        abstract: "Guitar Hero Live Bluetooth Low Energy controller bridge command line tool.",
        subcommands: [
            Connect.self,
            Generate.self
        ],
        defaultSubcommand: Connect.self
    )

    init() {

    }
}

Runner.main()
