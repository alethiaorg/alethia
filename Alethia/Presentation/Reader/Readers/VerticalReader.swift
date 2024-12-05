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
    
    @State private var position: ScrollPosition = .init(id: 0, anchor: .top)
    
    var body: some View {
        ZStack {
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
            .edgesIgnoringSafeArea(.top)
            .defaultScrollAnchor(.top)
            .scrollPosition($position)
            .onAppear {
                if let currentID = position.viewID as? Int, currentID != vm.currentPage {
                    position.scrollTo(id: vm.currentPage, anchor: .top)
                    DispatchQueue.main.async {
                        withAnimation {
                            vm.paintedScreen = true
                        }
                    }
                } else {
                    withAnimation {
                        vm.paintedScreen = true
                    }
                }
            }
            .onChange(of: vm.currentPage) {
                if let currentID = position.viewID as? Int, currentID != vm.currentPage {
                    position.scrollTo(id: vm.currentPage)
                }
            }
            .onChange(of: position) { oldPosition, newPosition in
                guard   oldPosition != newPosition,
                        let newIndex = newPosition.viewID as? Int,
                        vm.currentPage != newIndex
                else { return }

                vm.currentPage = newIndex
            }
            /// Do not use view-aligned for .Webtoon behaviour! -->
            /// On scans that split chapter images to small parts this will
            /// prevent user from ever scrolling to next page naturally
            /// See: mdex - 306606ed-9272-40d7-9534-c552d7e13f32
            .if(vm.settings.readDirection == .Vertical) { view in
                view.scrollTargetBehavior(.paging)
            }
        }
    }
    
    @ViewBuilder
    private func ScrollContent() -> some View {
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

