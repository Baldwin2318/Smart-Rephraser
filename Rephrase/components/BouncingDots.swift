//
//  BouncingDots.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2025-06-18.
//

import SwiftUI

struct BouncingDots: View {
    @State private var scale: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale[i])
                    .animation(Animation
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(i) * 0.2), value: scale[i])
            }
        }
        .onAppear {
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    scale[i] = 0.5
                }
            }
        }
    }
}
