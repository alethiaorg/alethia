//
//  HorizontalReader.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/11/2024.
//

import SwiftUI

struct HorizontalReader: View {
    @EnvironmentObject var vm: ReaderViewModel
    let contents: [String]
    
    var body: some View {
        TabView(selection: $vm.currentPage) {
            if vm.canGoBack {
                Text("")
                    .tag(-2)
            }
            
            PreviousChapterView()
                .tag(-1)
            
            ForEach(Array(contents.enumerated()), id: \.element) { index, imageUrlString in
                Group {
                    if let url = URL(string: imageUrlString) {
                        RetryableImage(
                            url: url,
                            index: index,
                            referer: vm.currentChapter.origin?.referer ?? ""
                        )
                        .tag(index)
                    } else {
                        Text("Invalid image URL")
                            .tag(index)
                    }
                }
            }
            
            NextChapterView()
                .tag(contents.count)
            
            if vm.canGoForward {
                Text("")
                    .tag(contents.count + 1)
            }
        }
        .environment(\.layoutDirection, vm.settings.readDirection == .RTL ? .rightToLeft : .leftToRight) // Already handled if horizontal so just check if RTL here
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .onChange(of: vm.currentPage) { newPage, oldPage in
            if oldPage == -2 {
                vm.goToPreviousChapter()
            }
            else if oldPage == contents.count + 1 {
                vm.goToNextChapter()
            }
        }
    }
}
