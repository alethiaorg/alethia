//
//  VerticalReader.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/11/2024.
//

import SwiftUI

struct VerticalReader: View {
    @EnvironmentObject var vm: ReaderViewModel
    let contents: [String]
    
    var body: some View {
        VStack {
            RefreshableScrollView(
                content: {
                    ScrollContent()
                },
                header: { state in
                    PreviousChapterView(state)
                },
                footer: { state in
                    NextChapterView(state)
                },
                canRefreshHeader: vm.canGoBack,
                canRefreshFooter: vm.canGoForward,
                onRefreshHeader: {
                    vm.goToPreviousChapter()
                },
                onRefreshFooter: {
                    vm.goToNextChapter()
                }
            )
            .defaultScrollAnchor(.top)
            .scrollPosition(
                id: Binding<Int?>(
                    get: { vm.currentPage },
                    set: { newValue in
                        if let newValue = newValue {
                            vm.currentPage = newValue
                        }
                    }
                ),
                anchor: .top
            )
            .if(vm.settings.readDirection == .Vertical) { view in
                view.scrollTargetBehavior(.paging)
            } else: { view in
                view.scrollTargetBehavior(.viewAligned)
            }
        }
        // Need to define here otherwise overlay will be ignored as well
        .edgesIgnoringSafeArea(.top)
    }
    
    @ViewBuilder
    private func ScrollContent() -> some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ForEach(Array(contents.enumerated()), id: \.element) { index, imageUrlString in
                    Group {
                        if let url = URL(string: imageUrlString) {
                            RetryableImage(
                                url: url,
                                index: index,
                                referer: vm.currentChapter.origin?.referer ?? ""
                            )
                        } else {
                            Text("Invalid image URL")
                                .tag(index)
                        }
                    }
                    .id(index)
                    .containerRelativeFrame(
                        vm.settings.readDirection == ReaderDirection.Webtoon ?
                            .horizontal :
                                .vertical
                        , count: 1,
                        spacing: 0
                    )
                }
            }
            .scrollTargetLayout()
            .onAppear {
                proxy.scrollTo(vm.currentPage, anchor: .top)
            }
        }
    }
    
    @ViewBuilder
    private func PreviousChapterView(_ state: RefreshState) -> some View {
        let canRelease = state != .pullDown
        
        if vm.canGoBack {
            let prevChapter = vm.chapters[vm.currentIndex + 1]
            HStack {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20))
                    .rotationEffect(.init(degrees: canRelease ? 0 : 180))
                
                Spacer()
                
                VStack {
                    Text(canRelease ? "Pull to Previous Chapter" : "Release To Previous Chapter")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text(prevChapter.toString())
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("Published by: \(prevChapter.scanlator)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 20))
                    .rotationEffect(.init(degrees: canRelease ? 0 : 180))
            }
            .padding()
        }
        else {
            Text("There is no previous chapter.")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func NextChapterView(_ state: RefreshState) -> some View {
        let canRelease = state != .pullUp
        
        if vm.canGoForward {
            let nextChapter = vm.chapters[vm.currentIndex - 1]
            
            HStack {
                Image(systemName: "arrow.down")
                    .font(.system(size: 20))
                    .rotationEffect(.init(degrees: canRelease ? 0 : 180))
                
                Spacer()
                
                VStack {
                    Text(canRelease ? "Pull to Next Chapter" : "Release To Next Chapter")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text(nextChapter.toString())
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("Published by: \(nextChapter.scanlator)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 20))
                    .rotationEffect(.init(degrees: canRelease ? 0 : 180))
            }
            .padding()
        }
        else {
            Text("There is no next chapter.")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

