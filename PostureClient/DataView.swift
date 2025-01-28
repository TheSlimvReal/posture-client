
//  DataView.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 18.01.25.
//

import SwiftUI

struct DataView: View {
    let service: BLEService
    let peripheral: BLEPeripheral
    var body: some View {
        VStack {
            Text(self.peripheral.name)
                .font(.title)
            if self.service.isConnected && !self.service.receivedData.isEmpty {
                List(self.service.receivedData, id: \.self) { val in
                    Text("Data \(val.left)")
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

#Preview {
    DataView(service: BLEServiceMock(), peripheral: BLEPeripheral())
}
