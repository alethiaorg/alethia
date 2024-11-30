//
//  VerticalReader.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/11/2024.
//

import SwiftUI

struct VerticalReader: View {
    @EnvironmentObject var controller: ReaderControls
    let contents: [String]
    
    @State private var yOffset: CGFloat = 0
    
    let THRESHOLD: CGFloat = 200
    
    var body: some View {
        ScrollContent()
    }
    
    @ViewBuilder
    private func ScrollContent() -> some View {
        ScrollView {
            ScrollViewReader { proxy in
                if controller.canGoBack {
                    PreviousChapterView()
                        .id(-1)
                }
                
                VStack(spacing: 0) {
                    ForEach(Array(contents.enumerated()), id: \.element) { index, imageUrlString in
                        Group {
                            if let url = URL(string: imageUrlString) {
                                RetryableImage(
                                    url: url,
                                    index: index,
                                    referer: controller.currentChapter.origin?.referer ?? ""
                                )
                            } else {
                                Text("Invalid image URL")
                                    .tag(index)
                            }
                        }
                        .id(index)
                        .containerRelativeFrame(
                            controller.settings.readDirection == ReaderDirection.Webtoon ?
                                .horizontal :
                                    .vertical
                            , count: 1,
                            spacing: 0
                        )
                    }
                }
                .scrollTargetLayout()
                .onAppear {
                    DispatchQueue.main.async {
                        // top anchor so scrollTo jumps to top of image not middle
                        proxy.scrollTo(controller.currentPage, anchor: .top)
                    }
                }
                
                if controller.canGoForward {
                    NextChapterView()
                        .id(contents.count)
                }
            }
        }
        .contentMargins(0, for: .scrollIndicators)
        .edgesIgnoringSafeArea(.all)
        .scrollPosition(id: Binding<Int?>(
            get: { controller.currentPage },
            set: { newValue in
                if let newValue = newValue {
                    controller.currentPage = newValue
                }
            }
        ))
        .defaultScrollAnchor(.top)
        .if(
            controller.settings.readDirection == .Vertical
        ) { view in
            view.scrollTargetBehavior(.paging)
        } else: { view in
            view.scrollTargetBehavior(.viewAligned)
        }
    }
}

