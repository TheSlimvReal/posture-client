//
//  BLEDelegate.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 18.01.25.
//
import CoreBluetooth
import Foundation
import SwiftUI

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

struct PostureColor {
    var left: Color = .green
    var right: Color = .green
    var forward: Color = .green
    var backward: Color = .green
}

@Observable class BLEService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var isConnected = false;
    var discoveredPeripherals: [CBPeripheral] = []
    var receivedData: [SensorData] = []
    var postureData: [PostureData] = []
    var postureColor = PostureColor()
        
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var dataService = CBUUID(string: "180A")
    private var resistanceCharacteristic = CBUUID(string: "2A58")
    
    private let timeframe = 5
    var defaultValues = SensorData(left: 1500, middle: 1500, right: 1500)
    
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
        print("connected")
        self.isConnected = true
        self.peripheral?.discoverServices([self.dataService])
        self.peripheral?.delegate = self
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("discovered")
        if let services = peripheral.services{
            for service in services{
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    var characteristicData: [CBCharacteristic] = []

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discovered characteristic")
        for charac in service.characteristics!{
            print("characteristic \(charac.uuid)")
            characteristicData.append(charac)
            if charac.uuid == self.resistanceCharacteristic{
                peripheral.setNotifyValue(true, for: charac)
                peripheral.readValue(for: charac)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
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
        let timeFrameData = self.receivedData.suffix(self.timeframe)
        print("time frame \(timeFrameData)")
//        let postureMeassure = self.analyzeWithThreshold(timeFrameData: timeFrameData)
        let postureMeassure = self.analyzeWithAvg(timeFrameData: timeFrameData)
        print("measured \(postureMeassure)")
        self.postureData.append(postureMeassure)
        self.setPostureColor(postureData: postureMeassure)
    }
    
    func analyzeWithThreshold(timeFrameData: ArraySlice<SensorData>) -> PostureData {
        let threshold = 200
        let accuracy = 3
        
        var postureMeassure = PostureData()
        var leftGreater = 0
        var leftSmaller = 0
        var rightGreater = 0
        var rightSmaller = 0
        var middleGreater = 0
        var middleSmaller = 0
        timeFrameData.forEach { d in
            if d.left > self.defaultValues.left + threshold {
                leftGreater += 1
            }
            if d.middle > self.defaultValues.middle + threshold {
                middleGreater += 1
            }
            if d.right > self.defaultValues.right + threshold {
                rightGreater += 1
            }
            if d.left < self.defaultValues.left - threshold/2 {
                leftSmaller += 1
            }
            if d.middle < self.defaultValues.middle - threshold/2 {
                middleSmaller += 1
            }
            if d.right < self.defaultValues.right - threshold/2 {
                rightSmaller += 1
            }
        }
        postureMeassure.left = leftGreater >= accuracy && rightSmaller >= accuracy
        postureMeassure.right = rightGreater >= accuracy && leftSmaller >= accuracy
        postureMeassure.backward = middleSmaller > accuracy
        postureMeassure.forward = middleGreater > accuracy
        return postureMeassure
    }
    
    func analyzeWithAvg(timeFrameData: ArraySlice<SensorData>) -> PostureData {
        let thresholdLR = 150
        let thresholdF = 50
        var postureMeassure = PostureData()
        let avgLeft = timeFrameData.reduce(0, { res, next in res + next.left }) / self.timeframe
        let avgRight = timeFrameData.reduce(0, { res, next in res + next.right }) / self.timeframe
        let avgMiddle = timeFrameData.reduce(0, { res, next in res + next.middle }) / self.timeframe
        postureMeassure.forward = avgMiddle > self.defaultValues.middle + thresholdF
        postureMeassure.backward = avgMiddle < self.defaultValues.middle - thresholdF / 2
        postureMeassure.right = (avgLeft > self.defaultValues.left + thresholdLR)
        postureMeassure.left = (avgRight > self.defaultValues.right + thresholdLR)
        return postureMeassure
    }
    
    func setDefault() {
        let timeFrameData = self.receivedData.suffix(self.timeframe)
        self.defaultValues.left = timeFrameData.reduce(0, { res, next in res + next.left }) / self.timeframe
        self.defaultValues.right = timeFrameData.reduce(0, { res, next in res + next.right }) / self.timeframe
        self.defaultValues.middle = timeFrameData.reduce(0, { res, next in res + next.middle }) / self.timeframe
        print("defaults \(self.defaultValues)")
    }
    
    func setPostureColor(postureData: PostureData) {
        withAnimation {
            self.postureColor.backward = postureData.backward ? .red : .green
            self.postureColor.forward = postureData.forward ? .red : .green
            self.postureColor.left = postureData.left ? .red : .green
            self.postureColor.right = postureData.right ? .red : .green
        }
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
