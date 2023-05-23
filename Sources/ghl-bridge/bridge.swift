import CoreBluetooth
import CoreGraphics
import Chalk

let targetServiceUUID = CBUUID(string: "533E1524-3ABE-F33F-CD00-594E8B0A8EA3")
let targetCharacteristicUUID = CBUUID(string: "533E1524-3ABE-F33F-CD00-594E8B0A8EA3")

class BLEBridge: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!

    private var _lastReceivedValue: String?
    private var _fretState: [Int: Bool] = [:]
    private var _buttonState: [Int: Bool] = [:]
    private var _strumState: UInt16 = 0x80

    private var _showKeyActions = false
    private var _disableKeyOutput = false

    private var _keyMap: KeyMap!

    init(_ keyMap: KeyMap, _ showKeyActions: Bool = false, _ disableKeyOutput: Bool = false) {
        super.init()
        _keyMap = keyMap
        _showKeyActions = showKeyActions
        _disableKeyOutput = disableKeyOutput
    }

    init(showKeyActions: Bool = false, disableKeyOutput: Bool = false) {
        super.init()
        _showKeyActions = showKeyActions
        _disableKeyOutput = disableKeyOutput
    }

    func run() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("\("Powered on - scanning for Ble Guitar ...", color: .blue)")
            centralManager.scanForPeripherals(withServices: [])
        default:
            print("Central Manager is not powered on")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {

        if peripheral.name == "Ble Guitar" {
          self.peripheral = peripheral
          self.peripheral.delegate = self
          self.centralManager.stopScan()
          self.centralManager.connect(self.peripheral)
          print("\("Connected to Ble Guitar!", color: .green)")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.peripheral.discoverServices([])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Failed to discover services: \(error)")
            return
        }

        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics([targetCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Failed to discover characteristics: \(error)")
            return
        }

        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == targetCharacteristicUUID && characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {

        if let error = error {
            print("Failed to update notification state: \(error)")
            return
        }

        if !characteristic.isNotifying {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to get updated value for characteristic: \(error)")
            return
        }

        if let data = characteristic.value {
            handleUpdate(data)
        }
    }

    /**
     +--------+-------+-------+-------+-------+-------+-------+-------+-------+
     |        | Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
     +--------+-------+-------+-------+-------+-------+-------+-------+-------+
     | Byte 0 | SDown |  SUp  |   W3  |   W2  |   W1  |   B3  |   B2  |   B1  |
     +--------+-------+-------+-------+-------+-------+-------+-------+-------+
     | Byte 1 |       |       |       |       | Power |  Hero |  GHTV | Pause |
     +--------+-------+-------+-------+-------+-------+-------+-------+-------+
     | Byte 2 |                        Whammy (0 - 127)                       |
     +--------+---------------------------------------------------------------+
     | Byte 3 |                      Tilt (0 - 128 - 255)                     |
     +--------+---------------------------------------------------------------+
    */

    fileprivate func handleUpdate(_ data: Data) {
        let dataMap = data.map { String(format: "%02x", $0) }.joined()
        // Ignore the tilt & whammy
        let hex = String(dataMap.dropLast(30))

        if hex != _lastReceivedValue {
            _fretState = processUpdate(data[0], _keyMap.frets, _fretState)
            _buttonState = processUpdate(data[1], _keyMap.buttons, _buttonState)
            _strumState = processUpdate(data[4], _keyMap.strum, _strumState)
            _lastReceivedValue = hex
        }
    }

    fileprivate func processUpdate(_ byte: UInt8, _ maps: [Map], _ state: [Int: Bool]) -> [Int: Bool] {
        var retState = state

        for map in maps {
            let isButtonPressed = Int(byte) & map.buttonMask != 0
            let wasButtonPressed = retState[map.buttonMask] ?? false

            if isButtonPressed && !wasButtonPressed {
                if _showKeyActions { print("\(map.name) pressed") }
                pressKeyDown(map.keyCode)
            } else if !isButtonPressed && wasButtonPressed {
                if _showKeyActions { print("\(map.name) released") }
                pressKeyUp(map.keyCode)
            }

            retState[map.buttonMask] = isButtonPressed
        }

        return retState
    }

    fileprivate func processUpdate(_ value: UInt8, _ maps: [Map], _ state: UInt16) -> UInt16 {

        for map in maps where map.buttonMask == value {
            if _showKeyActions { print(map.name) }
            pressKeyDown(map.keyCode)
            return map.keyCode
        }

        // If strum is neutral
        if value == 0x80 && state != value {
            pressKeyUp(state)
        }

        return 0x80
    }

    fileprivate func pressKeyDown(_ keyCode: CGKeyCode) {
        if !_disableKeyOutput {
            let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
            keyDownEvent?.post(tap: .cghidEventTap)
        }
    }

    fileprivate func pressKeyUp(_ keyCode: CGKeyCode) {
        if !_disableKeyOutput {
            let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
            keyUpEvent?.post(tap: .cghidEventTap)
        }
    }
}
