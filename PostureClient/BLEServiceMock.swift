//
//  BLEServiceMock.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 28.01.25.
//

import Foundation
import CoreBluetooth
import GameplayKit

@Observable class BLEServiceMock: BLEService {
    let random = GKRandomSource()
    let distribution: GKGaussianDistribution
    
    override init() {
        self.distribution = GKGaussianDistribution(randomSource: random, lowestValue: 500, highestValue: 2000)
    }

    override func connectPeripheral(peripheral: BLEPeripheral) {
        self.isConnected = true;
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(publishRandomData), userInfo: nil, repeats: true)
    }
    
    @objc func publishRandomData() {
        
        do {
            let left = self.distribution.nextInt();
            let middle = self.distribution.nextInt();
            let right = 2500 - left
            let mockData = SensorData(left: left, middle: middle, right: right)
            let jsonData = try JSONEncoder().encode(mockData)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let ascii = jsonString.compactMap(\.asciiValue)
            self.parseData(data: Data(ascii))
        } catch {
            print("error creating mock data \(error)")
        }
    }
}
