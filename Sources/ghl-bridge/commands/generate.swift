import ArgumentParser
import CoreBluetooth
import Foundation
import os.log
import Yams

private var log = OSLog(subsystem: "ghl-bridge", category: "bridge")

struct Generate: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Generates a YAML key mapping file")

    @Option(help: "Specify the file path")
    private var filePath: String = ""

    @Option(help: "Specify the file name")
    private var fileName: String = "keymap.yaml"

    func run() throws {
        let path = filePath == "" ? FileManager.default.currentDirectoryPath : filePath
        exportKeyMap(defaultKeyMap, to: path + "/" + fileName)
        print("Key mapping file \(fileName) generated at \(path). " +
              "Use this with 'ghl-bridge connect --map-file \(path)/\(fileName)'")
    }

    fileprivate func exportKeyMap(_ keyMap: KeyMap, to yamlFilePath: String) {
        do {
            let encoder = YAMLEncoder()
            let yamlString = try encoder.encode(keyMap)
            try yamlString.write(toFile: yamlFilePath, atomically: true, encoding: .utf8)
        } catch {
            print("Error exporting ButtonMap: \(error)")
        }
    }
}
