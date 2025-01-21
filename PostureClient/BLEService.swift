//
//  BLEDelegate.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 18.01.25.
//
import CoreBluetooth
import Foundation

@Observable class BLEService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var isConnected = false;
    var discoveredPeripherals: [CBPeripheral] = []
    var receivedData: [String] = []
    
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var dataService = CBUUID(string: "180A")
    private var resistanceCharacteristic = CBUUID(string: "2A58")
    
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
    
    func connectPeripheral(peripheral: CBPeripheral) {
        self.central!.stopScan()
        self.central!.connect(peripheral, options: nil)
        self.peripheral = peripheral
        print("EXPECTED_PERIPHERALS \(self.peripheral!)")
    }
    
    func disconnect(peripheral: CBPeripheral) {
        self.isConnected = false;
        self.receivedData = []
        self.central!.cancelPeripheralConnection(peripheral)
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

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
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
        
        
        if characteristic.uuid == self.resistanceCharacteristic{
            var resString = ""
            data.forEach { resString += String(UnicodeScalar($0)) }
            print("res \(resString)")
            self.receivedData.append(resString)
        }
    
    }
}
