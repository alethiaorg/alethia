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
    @EnvironmentObject var controller: ReaderViewModel
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
        if controller.settings.readDirection.isVertical {
            VerticalReader(contents: contents)
        } else {
            HorizontalReader(contents: contents)
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
                    currentPage: $controller.currentPage,
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
        .onChange(of: controller.currentPage) { old, new in
            guard !contents.isEmpty else { return }
            guard old != new else { return }
            
            prefetchImages()
            updateProgress()
        }
        .onChange(of: controller.currentIndex) { oldValue, newValue in
            isGoingToPreviousChapter = newValue > oldValue
            isGoingToNextChapter = newValue < oldValue
            withAnimation {
                currentChapterId = UUID()
            }
            loadChapterContent()
        }
    }
    
    private func transitionForCurrentDirection() -> AnyTransition {
        switch controller.settings.readDirection {
        case .LTR:
            return AnyTransition.move(edge: .trailing)
        case .RTL:
            return AnyTransition.move(edge: .leading)
        case .Vertical:
            fallthrough
        case .Webtoon:
            return AnyTransition.move(edge: .bottom)
        }
    }
    
    private func updateProgress() {
        let newProgress = max(0.0, min(Double(controller.currentPage) / Double(contents.count - 1), 1.0))
        controller.currentChapter.progress = newProgress
        
        try? modelContext.save()
    }
    
    private func loadChapterContent() {
        isLoading = true
        Task {
            do {
                var results = [String]()
                
                if controller.currentChapter.isDownloaded {
                    let ds = DownloadService(modelContext: modelContext)
                    results = try await ds.getChapter(controller.currentChapter)
                }
                else {
                    results = try await getChapterContent(chapter: controller.currentChapter)
                }
                
                await MainActor.run {
                    contents = results
                    isLoading = false
                    
                    /// When chapter content gets initially loaded:
                    /// - jump to last page if going to previous chapter or...
                    /// - load from the current chapter's progress
                    if isGoingToPreviousChapter {
                        controller.currentPage = contents.count - 1
                    }
                    else if isGoingToNextChapter {
                        controller.currentPage = 0
                    }
                    else {
                        let totalPages = contents.count
                        // Progress from 0.0 - 1.0
                        let currentProgress = max(0.0, min(controller.currentChapter.progress, 1.0))
                        
                        // Page from progress calc
                        let currentPage = Int(Double(totalPages - 1) * currentProgress)
                        
                        print("Total Pages: \(totalPages)")
                        print("Current Progress: \(currentProgress)")
                        print("Current Page:  (\(totalPages) - 1) * \(currentProgress) = \(currentPage)")
                        
                        controller.currentPage = currentPage
                        controller.createReadingHistory(modelContext: modelContext, startPage: controller.currentPage)
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
        let startIndex = max(0, controller.currentPage - PREFETCH_RANGE)
        let endIndex = min(contents.count - 1, controller.currentPage + PREFETCH_RANGE)
        
        guard startIndex <= endIndex else { return }
        
        let urlsToPrefetch = Array(contents[startIndex...endIndex]).map { URL(string: $0)! }
        
        prefetcher = ImagePrefetcher(
            urls: urlsToPrefetch,
            options: [.cacheOriginalImage],
            progressBlock: nil
        )
        
        prefetcher?.start()
    }
}
