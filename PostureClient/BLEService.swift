//
//  BLEDelegate.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 18.01.25.
//
import CoreBluetooth
import Foundation

struct SensorData: Codable, Hashable {
    var left: Int
    var middle: Int
    var right: Int
}

struct PostureData: Codable {
    var left: Bool = false
    var right: Bool = false
    var forward: Bool = false
    var backward: Bool = false
}

@Observable class BLEService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var isConnected = false;
    var discoveredPeripherals: [CBPeripheral] = []
    var receivedData: [SensorData] = []
    var postureData: [PostureData] = []
        
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var dataService = CBUUID(string: "180A")
    private var resistanceCharacteristic = CBUUID(string: "2A58")
    
    private var leftDefault = 1200
    private var middleDefault = 1200
    private var rightDefault = 1200
    
    func discoverPeripherals() {
        if self.central == nil {
            self.central = CBCentralManager(delegate: self, queue: nil)
        } else {
            self.discoveredPeripherals = []
            self.central?.scanForPeripherals(withServices: [self.dataService])
        }
    }
    
    func stopDiscover() {
        self.central?.stopScan()
    }
    
    func connectPeripheral(peripheral: BLEPeripheral) {
        self.central!.stopScan()
        self.central!.connect(peripheral.getPeripheral(), options: nil)
        self.peripheral = peripheral.getPeripheral()
        print("EXPECTED_PERIPHERALS \(self.peripheral!)")
    }
    
    func disconnect(peripheral: BLEPeripheral) {
        self.isConnected = false;
        self.receivedData = []
        self.postureData = []
        self.central!.cancelPeripheralConnection(peripheral.getPeripheral())
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("did update")
        if central.state == .poweredOn{
            central.scanForPeripherals(withServices: [self.dataService])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if self.discoveredPeripherals.first(where: { $0.identifier == peripheral.identifier}) == nil {
            self.discoveredPeripherals.append(peripheral)
        }
        print("peripherals \(self.discoveredPeripherals)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.isConnected = true
        self.peripheral?.discoverServices([self.dataService])
        self.peripheral?.delegate = self
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services{
            for service in services{
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    var characteristicData: [CBCharacteristic] = []

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService) {
        for charac in service.characteristics!{
            print("characteristic \(charac.uuid)")
            characteristicData.append(charac)
            if charac.uuid == self.resistanceCharacteristic{
                peripheral.setNotifyValue(true, for: charac)
                peripheral.readValue(for: charac)
            }
        }
    }
    
    func peripheral(didUpdateValueFor characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            return
        }
        
        print("peripheral \(characteristic.value!)")

        if characteristic.uuid == self.resistanceCharacteristic {
            self.parseData(data: data)
        }
    }
    
    func parseData(data: Data) {
        var resString = ""
        data.forEach { resString += String(UnicodeScalar($0)) }
        let decoder = JSONDecoder()
        do {
            let sensorData = try decoder.decode(SensorData.self, from: resString.data(using: .utf8)!)
            print("res \(sensorData)")
            self.receivedData.append(sensorData)
            self.getPostureData()
        } catch {
            print("Failed decoding data \(decoder) Error: \(error)")
        }
    }
    
    func getPostureData() {
        let timeFrame = 5
        let threshold = 200
        let accuracy = 3
        
        var postureMeassure = PostureData()
        if self.receivedData.count > timeFrame {
            let timeFrameData = self.receivedData.suffix(5)
            print("time frame \(timeFrameData)")
            var leftGreater = 0
            var leftSmaller = 0
            var rightGreater = 0
            var rightSmaller = 0
            var middleGreater = 0
            var middleSmaller = 0
            timeFrameData.forEach { d in
                if d.left > self.leftDefault + threshold {
                    leftGreater += 1
                }
                if d.middle > self.middleDefault + threshold {
                    middleGreater += 1
                }
                if d.right > self.rightDefault + threshold {
                    rightGreater += 1
                }
                if d.left < self.leftDefault - threshold/2 {
                    leftSmaller += 1
                }
                if d.middle < self.middleDefault - threshold/2 {
                    middleSmaller += 1
                }
                if d.right < self.rightDefault - threshold/2 {
                    rightSmaller += 1
                }
            }
            postureMeassure.left = leftGreater >= accuracy && rightSmaller >= accuracy
            postureMeassure.right = rightGreater >= accuracy && leftSmaller >= accuracy
            postureMeassure.backward = middleSmaller > accuracy
            postureMeassure.forward = middleGreater > accuracy
            print("measured \(postureMeassure)")
        }
        self.postureData.append(postureMeassure)
    }
}

class BLEPeripheral: NSObject {
    private var peripheral: CBPeripheral?
    
    var name: String {
        get {
            if self.peripheral === nil {
                return "Mocked"
            } else {
                return self.peripheral!.name ?? "unnamed"
            }
        }
    }
    
    init(peripheral: CBPeripheral? = nil) {
        self.peripheral = peripheral
    }
    
    func getPeripheral() -> CBPeripheral {
        return self.peripheral!
    }
    
    func setPeripheral(peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }
}
