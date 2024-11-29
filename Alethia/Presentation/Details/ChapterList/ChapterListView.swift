//
//  ChapterListView.swift
//  Alethia
//
//  Created by Angelo Carasig on 29/11/2024.
//

import SwiftUI

struct ChapterListView: View {
    let manga: Manga
    
    @State var vm: ChapterListViewModel
    
    init(manga: Manga) {
        self.manga = manga
        _vm = State(initialValue: ChapterListViewModel(manga: manga))
    }
    
    var body: some View {
        NavigationStack {
            ChapterListHeaderView(vm: vm)
            
            Divider()
            
            ChapterListContentView(vm: vm)
        }
        .onChange(of: manga.origins) {
            vm.updateChapters()
        }
    }
}
