import ArgumentParser
import CoreBluetooth
import Foundation
import os.log
import Yams

private var log = OSLog(subsystem: "ghl-bridge", category: "bridge")

struct Connect: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Connect to a GHL controller")

    @Option(help: "Specify the custom keymap YAML file path")
    private var mapFile: String = ""

    @Flag()
    var printKeyActions = false

    @Flag()
    var disableKeyOutput = false

    func loop() {
        signal(SIGINT, SIG_IGN)
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSrc.setEventHandler {
            Foundation.exit(0)
        }
        sigintSrc.resume()
        let loop = RunLoop.current
        while loop.run(mode: .default, before: Date.distantFuture) {
            loop.run()
        }
    }

    func run() throws {
        var keyMap = defaultKeyMap

        if mapFile != "" {
            if let customKeyMap: KeyMap = loadMap(from: mapFile) {
                keyMap = customKeyMap
            }
        }

        let bridge: BLEBridge = BLEBridge(keyMap, printKeyActions, disableKeyOutput)
        bridge.run()
        self.loop()
    }

    func loadMap(from yamlFilePath: String) -> KeyMap? {
        do {
            let yamlString = try String(contentsOfFile: yamlFilePath, encoding: .utf8)
            let decoder = YAMLDecoder()
            let keyMap = try decoder.decode(KeyMap.self, from: yamlString)
            return keyMap
        } catch {
            print("Error loading key map from YAML: \(error)")
            return nil
        }
    }
}
