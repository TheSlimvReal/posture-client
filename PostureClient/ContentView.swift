//
//  ContentView.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 14.01.25.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    let bleService = BLEService()
    var body: some View {
        NavigationSplitView {
            VStack {
                if (bleService.discoveredPeripherals.isEmpty) {
                    Text("Looking for devices nearby...")
                } else {
                    List(self.bleService.discoveredPeripherals, id: \.identifier) { peripheral in
                        NavigationLink {
                            DataView(service: self.bleService, peripheral: BLEPeripheral(peripheral: peripheral))
                        } label: {
                            Text("\(peripheral.name ?? "unnamed") - \(peripheral.identifier)")
                        }
                    }
                        .navigationTitle("Devices")
                }
            }
            .padding()
            .onAppear {
                self.bleService.discoverPeripherals()
            }
            .onDisappear {
                self.bleService.stopDiscover()
            }
        } detail: {
            Text("Select a device")
        }

    }

}

#Preview {
    ContentView()
}
