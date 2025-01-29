//
//  ChartView.swift
//  PostureClient
//
//  Created by Simon Hanselmann on 28.01.25.
//

import SwiftUI
import Charts

struct ChartView: View {
    let data: [SensorData]
    let defaultValues: SensorData
    var body: some View {
        Chart {
            ForEach(Array(zip(self.data.indices, self.data)), id: \.1.left) { index, item in
                LineMark(
                    x: .value("Time", -index),
                    y: .value("Value", item.left - self.defaultValues.left),
                    series: .value("Series", "left")
                ).foregroundStyle(by: .value("Series", "left"))
                LineMark(
                    x: .value("Time", -index),
                    y: .value("Value", item.middle - self.defaultValues.middle),
                    series: .value("Series", "middle")
                ).foregroundStyle(by: .value("Series", "middle"))
                LineMark(
                    x: .value("Time", -index),
                    y: .value("Value", item.right - self.defaultValues.right),
                    series: .value("Series", "right")
                ).foregroundStyle(by: .value("Series", "right"))
            }
        }
        .chartXScale(domain: [-10, 0])
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    Text("\(value.as(Int.self)!)s")
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    Text("\(value.as(Int.self)!)Ω")
                }
            }
        }
        .chartForegroundStyleScale([
            "left": .yellow, "middle": .green, "right": .red
        ])
    }
}

#Preview {
    ChartView(data: [
        .init(left: 1200, middle: 1200, right: 1200),
        .init(left: 1300, middle: 1200, right: 1100),
        .init(left: 1400, middle: 1800, right: 1000),
        .init(left: 900, middle: 1500, right: 1500)
    ], defaultValues: .init(left: 1200, middle: 1300, right: 1100))
}
