//
//  ReaderContent.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/12/2024.
//

import SwiftUI
import Kingfisher

struct ReaderContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var vm: ReaderViewModel
    @AppStorage("prefetch") private(set) var PREFETCH_RANGE = 0
    
    @State private var contents = [String]()
    @State private var isLoading = true
    @State private var error: Error?
    
    @State private var isGoingToPreviousChapter = false
    @State private var isGoingToNextChapter = false
    
    @State private var prefetcher: ImagePrefetcher?
    
    @Namespace private var transitionNamespace
    @State private var currentChapterId: UUID = UUID()
    
    @ViewBuilder
    private func LoadingView() -> some View {
        ProgressView("Loading Chapter Content..")
    }
    
    @ViewBuilder
    private func ErrorView(error: Error) -> some View {
        VStack {
            Spacer()
            Button("Back to Home") { dismiss() }
            Spacer()
            Text("Error: \(error.localizedDescription)")
            Spacer()
            Button("Try Again?") { loadChapterContent() }
            Spacer()
        }
    }
    
    @ViewBuilder
    private func EmptyContentView() -> some View {
        VStack {
            Spacer()
            Button("Back to Home") { dismiss() }
            Spacer()
            Text("No Chapter Content for this Chapter.")
            Spacer()
            Button("Try Again?") { loadChapterContent() }
            Spacer()
        }
    }
    
    @ViewBuilder private func Reader() -> some View {
        if vm.settings.readDirection.isVertical {
            VerticalReader(contents: contents)
        } else {
            HorizontalReader(contents: contents)
                // Need to prevent interaction until content loaded and the onAppear .scrollTo triggers
                .allowsHitTesting(vm.paintedScreen)
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(error: error)
            } else if contents.isEmpty {
                EmptyContentView()
            } else {
                ReaderOverlay(
                    currentPage: $vm.currentPage,
                    isOverlayVisible: $vm.isOverlayVisible,
                    totalPages: contents.count
                ) {
                    Reader()
                }
                .id(currentChapterId)
            }
        }
        .transition(transitionForCurrentDirection())
        .animation(.easeInOut, value: currentChapterId)
        .onAppear {
            loadChapterContent()
        }
        .onChange(of: vm.currentPage) { old, new in
            guard !contents.isEmpty, old != new else { return }
            
            prefetchImages()
        }
        .onChange(of: vm.currentIndex) { oldValue, newValue in
            // Need to update chapter from old index value
            updateProgress(vm.chapters[oldValue])
            
            isGoingToPreviousChapter = newValue > oldValue
            isGoingToNextChapter = newValue < oldValue
            withAnimation {
                currentChapterId = UUID()
                vm.paintedScreen = false
            }
            loadChapterContent()
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                updateProgress(vm.currentChapter)
            }
        }
        .onDisappear {
            updateProgress(vm.currentChapter)
        }
    }
    
    private func transitionForCurrentDirection() -> AnyTransition {
        let transition: AnyTransition
        switch vm.settings.readDirection {
        case .LTR:
            transition = .push(from: .trailing)
        case .RTL:
            transition = .push(from: .leading)
        case .Vertical:
            fallthrough
        case .Webtoon:
            transition = .push(from: isGoingToPreviousChapter ? .top : .bottom)
        }
        
        return transition.combined(with: .opacity)
            .animation(.easeInOut)
    }
    
    private func loadChapterContent() {
        isLoading = true
        Task {
            do {
                var results = [String]()
                
                if vm.currentChapter.isDownloaded {
                    let ds = DownloadService(modelContext: modelContext)
                    results = try await ds.getChapter(vm.currentChapter)
                }
                else {
                    results = try await getChapterContent(chapter: vm.currentChapter)
                }
                
                await MainActor.run {
                    contents = results
                    isLoading = false
                    
                    /// When chapter content gets initially loaded:
                    /// - jump to last page if going to previous chapter or...
                    /// - load from the current chapter's progress
                    if isGoingToPreviousChapter {
                        vm.currentPage = contents.count - 1
                    }
                    else if isGoingToNextChapter {
                        vm.currentPage = 0
                    }
                    else {
                        let totalPages = contents.count
                        // Progress from 0.0 - 1.0
                        let currentProgress = max(0.0, min(vm.currentChapter.progress, 1.0))
                        
                        // Page from progress calc
                        let currentPage = Int(Double(totalPages - 1) * currentProgress)
                        
                        print("Total Pages: \(totalPages)")
                        print("Current Progress: \(currentProgress)")
                        print("Current Page:  (\(totalPages) - 1) * \(currentProgress) = \(currentPage)")
                        
                        vm.currentPage = currentPage
                        vm.createReadingHistory(modelContext: modelContext, startPage: vm.currentPage)
                    }
                    
                    isGoingToPreviousChapter = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    // Eager loading
    private func prefetchImages() {
        prefetcher?.stop()
        
        guard !contents.isEmpty else { return }
        
        // Calculate the range of indices to prefetch
        let startIndex = max(0, vm.currentPage - PREFETCH_RANGE)
        let endIndex = min(contents.count - 1, vm.currentPage + PREFETCH_RANGE)
        
        guard startIndex <= endIndex else { return }
        
        let urlsToPrefetch = Array(contents[startIndex...endIndex]).map { URL(string: $0)! }
        
        prefetcher = ImagePrefetcher(
            urls: urlsToPrefetch,
            options: [.cacheOriginalImage],
            progressBlock: nil
        )
        
        prefetcher?.start()
    }
    
    private func updateProgress(_ chapter: Chapter) {
        // Lag occurs when updating per page, better to update whenever index changes or on disappear etc.
        let newProgress = max(0.0, min(Double(vm.currentPage) / Double(contents.count - 1), 1.0))
        withAnimation {
            chapter.progress = newProgress

            try? modelContext.save()
        }
    }
}
