//
//  main.swift
//  ghl-bridge
//
//  Created by barlind on 2023-05-21.
//

import CoreBluetooth
import CoreGraphics
import Chalk

let targetServiceUUID = CBUUID(string: "533E1524-3ABE-F33F-CD00-594E8B0A8EA3")
let targetCharacteristicUUID = CBUUID(string: "533E1524-3ABE-F33F-CD00-594E8B0A8EA3")

let fretMap: [(buttonMask: Int, keyCode: CGKeyCode, name: String)] = [
    (0x02, 0x12, "B1"), // -> '1'
    (0x04, 0x13, "B2"), // -> '2'
    (0x08, 0x14, "B3"), // -> '3'
    (0x01, 0x15, "W1"), // -> '4'
    (0x10, 0x17, "W2"), // -> '5'
    (0x20, 0x16, "W3")  // -> '6'
]

let buttonMap: [(buttonMask: Int, keyCode: CGKeyCode, name: String)] = [
    (0x02, 0x2F, "GHTV"), // -> '.'
    (0x04, 0x13, "Pause"), // -> 'Return'
    (0x08, 0x14, "Star Power"), // -> 'S'
]

class GHLBridge: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
        
    private var lastReceivedValue: String?
    private var fretState: [Int: Bool] = [:]
    private var buttonState: [Int: Bool] = [:]
    private var strumState: UInt16 = 0x80
    
    override init() {
        super.init()
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "Ble Guitar" {
          self.peripheral = peripheral
          self.peripheral.delegate = self
          self.centralManager.stopScan()
          self.centralManager.connect(self.peripheral)
          print("Connected to Ble Guitar!")
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
            if characteristic.uuid == targetCharacteristicUUID {
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
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
        
        //Ignore the tilt & whammy
        let hex = String(dataMap.dropLast(30))
        
        if hex != lastReceivedValue {
            fretState = processUpdate(data[0], fretMap, fretState)
            buttonState = processUpdate(data[1], buttonMap, buttonState)
            strumState = processUpdate(data[4], strumState)
            lastReceivedValue = hex
        }
    }
    
    fileprivate func processUpdate(_ byte: UInt8, _ map: [(buttonMask: Int, keyCode: CGKeyCode, name: String)], _ state: [Int: Bool]) -> [Int: Bool] {
        var retState = state
        
        for (buttonMask, keyCode, name) in map {
            let isButtonPressed = Int(byte) & buttonMask != 0
            let wasButtonPressed = retState[buttonMask] ?? false
            
            if isButtonPressed && !wasButtonPressed {
                print("Button \(name) pressed")
                pressKeyDown(keyCode)
            } else if !isButtonPressed && wasButtonPressed {
                print("Button \(name) released")
                pressKeyUp(keyCode)
            }
            
            retState[buttonMask] = isButtonPressed
        }
        
        return retState
    }
    
    fileprivate func processUpdate(_ value: UInt8, _ state: UInt16) -> UInt16 {
        if (value == 0x80 && state != value) {
            pressKeyUp(state)
            return 0x80
        }
        else if(value == 0x00) {
            print("Strum UP")
            pressKeyDown(0x00)
            return 0x00
        }
        else if(value == 0xff) {
            print("Strum DOWN")
            pressKeyDown(0x0B)
            return 0x0B
        }
        return 0x80
    }
        
    fileprivate func pressKey(_ keyCode: CGKeyCode) {
        pressKeyDown(keyCode)
        pressKeyUp(keyCode)
    }
    
    fileprivate func pressKeyDown(_ keyCode: CGKeyCode) {
        let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        keyDownEvent?.post(tap: .cghidEventTap)
    }

    fileprivate func pressKeyUp(_ keyCode: CGKeyCode) {
        let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyUpEvent?.post(tap: .cghidEventTap)
    }
    
}

let ghlBridge = GHLBridge()

RunLoop.main.run() // This is required to keep the program running, as BLE operation is asynchronous
