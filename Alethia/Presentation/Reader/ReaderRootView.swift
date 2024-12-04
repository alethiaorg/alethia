//
//  ReaderRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher
import Zoomable

struct ReaderRootView: View {
    @StateObject private var vm: ReaderViewModel
    @Environment(\.modelContext) private var modelContext
    
    init(settings: ChapterSettings, chapters: [Chapter], current: Int) {
        _vm = StateObject(wrappedValue: ReaderViewModel(
            settings: settings,
            chapters: chapters,
            currentIndex: current
        ))
    }
    
    var body: some View {
        ReaderContent()
            .environmentObject(vm)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
            .onDisappear {
                vm.updateReadingHistory(modelContext: modelContext)
            }
    }
}
