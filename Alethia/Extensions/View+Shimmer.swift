//
//  View+Shimmer.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import SwiftUI

extension View {
    func shimmer() -> some View {
        self
            .overlay(
                ShimmerView()
                    .mask(self)
            )
    }
}

private struct ShimmerView: View {
    @State private var startPoint: UnitPoint = .leading
    @State private var endPoint: UnitPoint = .trailing

    var body: some View {
        LinearGradient(gradient: Gradient(colors: [.clear, Color.background.opacity(0.6), .clear]),
                       startPoint: startPoint, endPoint: endPoint)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    startPoint = .trailing
                    endPoint = .leading
                }
            }
    }
}
