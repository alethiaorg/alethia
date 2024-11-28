//
//  NavigationButton.swift
//  Alethia
//
//  Created by Angelo Carasig on 25/11/2024.
//

import SwiftUI

/// NOTE: DO NOT USE ON ANY LAZY-LOADED CONTENT SUCH AS IN LAZYVSTACK/LAZYHGRID ETC.
struct NavigationButton<Destination: View, Label: View>: View {
    var action: () -> Void = { }
    @ViewBuilder var destination: () -> Destination
    @ViewBuilder var label: () -> Label
    
    @State private var isPresented: Bool = false
    
    var body: some View {
        Button(action: {
            self.action()
            self.isPresented.toggle()
        }) {
            self.label()
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $isPresented) {
            LazyDestination(destination: destination)
        }
    }
}

private struct LazyDestination<Destination: View>: View {
    @ViewBuilder var destination: () -> Destination
    
    var body: some View {
        self.destination()
    }
}
