
//  DataView.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 18.01.25.
//

import SwiftUI
import CoreBluetooth

struct DataView: View {
    let service: BLEService
    let peripheral: CBPeripheral
    var body: some View {
        VStack {
            Text(self.peripheral.name ?? "unnamed device")
                .font(.title)
            if self.service.isConnected && !self.service.receivedData.isEmpty {
                List(self.service.receivedData, id: \.self) { val in
                    Text("Data \(val)")
                }
            } else {
                Text("Connecting...")
            }
            Spacer()
        }
            .onAppear {
                self.service.connectPeripheral(peripheral: self.peripheral)
            }
            .onDisappear {
                self.service.disconnect(peripheral: self.peripheral)
        }

    }

}
