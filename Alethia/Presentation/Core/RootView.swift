//
//  RootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeRootView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            LibraryRootView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Library")
                }
            
            Text("Search")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            SourceRootView()
                .tabItem {
                    Image(systemName: "plus.square.dashed")
                    Text("Sources")
                }
            
            Text("History")
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
        }
    }
}

#Preview {
    RootView()
}
