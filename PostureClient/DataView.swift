
//  DataView.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 18.01.25.
//

import SwiftUI

struct DataView: View {
    let service: BLEService
    let peripheral: BLEPeripheral
    let radius: CGFloat = 150
    let centerPoint = CGPoint(x: 200, y: 200)
    var body: some View {
        VStack {
            ZStack {
                HStack{
                    Text(self.peripheral.name)
                        .font(.title)
                }
                HStack{
                    Spacer()
                    Button(action: self.service.setDefault) {
                        Image(systemName: "person").padding()
                    }.padding([.trailing])
                }
            }
            if self.service.isConnected && !self.service.receivedData.isEmpty {
                ZStack {
                    Path { path in
                        path.move(to: self.centerPoint)
                        path.addArc(
                            center: self.centerPoint,
                            radius: self.radius + 5,
                            startAngle: Angle(degrees: 0),
                            endAngle: Angle(degrees: 360),
                            clockwise: false
                        )
                    }.fill(.gray).shadow(radius: 7)
                    Path { path in
                        path.move(to: self.centerPoint)
                        path.addArc(
                            center: self.centerPoint,
                            radius: self.radius,
                            startAngle: Angle(degrees: 315),
                            endAngle: Angle(degrees: 45),
                            clockwise: false
                        )
                    }.fill(self.service.postureColor.right)
                    Path { path in
                        path.move(to: self.centerPoint)
                        path.addArc(
                            center: self.centerPoint,
                            radius: self.radius,
                            startAngle: Angle(degrees: 45),
                            endAngle: Angle(degrees: 135),
                            clockwise: false
                        )
                    }.fill(self.service.postureColor.backward)
                    Path { path in
                        path.move(to: self.centerPoint)
                        path.addArc(
                            center: CGPoint(x: 200, y:200),
                            radius: self.radius,
                            startAngle: Angle(degrees: 135),
                            endAngle: Angle(degrees: 225),
                            clockwise: false
                        )
                    }.fill(self.service.postureColor.left)
                    Path { path in
                        path.move(to: self.centerPoint)
                        path.addArc(
                            center: CGPoint(x: 200, y:200),
                            radius: self.radius,
                            startAngle: Angle(degrees: 225),
                            endAngle: Angle(degrees: 315),
                            clockwise: false
                        )
                    }.fill(self.service.postureColor.forward)
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
