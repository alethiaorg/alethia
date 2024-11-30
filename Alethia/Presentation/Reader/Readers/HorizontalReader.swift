//
//  HorizontalReader.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/11/2024.
//

import SwiftUI

struct HorizontalReader: View {
    @EnvironmentObject var controller: ReaderControls
    let contents: [String]
    
    var body: some View {
        TabView(selection: $controller.currentPage) {
            if controller.canGoBack {
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
                            referer: controller.currentChapter.origin?.referer ?? ""
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
            
            if controller.canGoForward {
                Text("")
                    .tag(contents.count + 1)
            }
        }
        .environment(\.layoutDirection, controller.settings.readDirection == .RTL ? .rightToLeft : .leftToRight) // Already handled if horizontal so just check if RTL here
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .onChange(of: controller.currentPage) { newPage, oldPage in
            if oldPage == -2 {
                controller.goToPreviousChapter()
            }
            else if oldPage == contents.count + 1 {
                controller.goToNextChapter()
            }
        }
    }
}
