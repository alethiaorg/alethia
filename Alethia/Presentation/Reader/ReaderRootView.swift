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
    @StateObject private var controller: ReaderControls
    @Environment(\.modelContext) private var modelContext
    
    init(settings: ChapterSettings, chapters: [Chapter], current: Int) {
        _controller = StateObject(wrappedValue: ReaderControls(
            settings: settings,
            chapters: chapters,
            currentIndex: current
        ))
    }
    
    var body: some View {
        ReaderContent()
            .environmentObject(controller)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
            .onDisappear {
                controller.updateReadingHistory(modelContext: modelContext)
            }
    }
}

class ReaderControls: ObservableObject {
    let settings: ChapterSettings
    let chapters: [Chapter]
    @Published var currentIndex: Int
    @Published var currentPage: Int = 0
    @Published var currentReadingHistory: ReadingHistory?
    
    init(
        settings: ChapterSettings,
        chapters: [Chapter],
        currentIndex: Int
    ) {
        self.settings = settings
        self.chapters = chapters
        self.currentIndex = currentIndex
    }
    
    var currentChapter: Chapter {
        chapters[currentIndex]
    }
    
    var canGoBack: Bool {
        currentIndex < chapters.count - 1
    }
    
    var canGoForward: Bool {
        currentIndex > 0
    }
    
    func goToPreviousChapter() {
        if canGoBack {
            currentIndex += 1
        }
    }
    
    func goToNextChapter() {
        if canGoForward {
            currentIndex -= 1
        }
    }
    
    func toggleReaderDirection(context: ModelContext) {
        settings.cycleReaderDirection()
        do {
            try context.save()
        }
        catch {
            print("Error Saving Chapter Setting Read Direction")
        }
    }
    
    func createReadingHistory(modelContext: ModelContext, startPage: Int) {
        let newHistory = ReadingHistory(
            startChapter: currentChapter,
            startPage: startPage
        )
        
        modelContext.insert(newHistory)
        currentReadingHistory = newHistory
    }
    
    func updateReadingHistory(modelContext: ModelContext) {
        guard let history = currentReadingHistory else { return }
        
        history.finishSession(
            endPage: currentPage,
            dateEnded: Date(),
            endChapter: currentChapter != history.startChapter ? currentChapter : nil
        )
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save reading history: \(error)")
        }
    }
}

private struct ReaderOverlay<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var controller: ReaderControls
    @State var isOverlayVisible: Bool = true
    @Binding var currentPage: Int {
        didSet {
            print("Current Page: \(currentPage)")
        }
    }
    let totalPages: Int
    let content: Content
    
    private var inContentRange: Bool {
        currentPage >= 0 && currentPage < totalPages
    }
    
    init(currentPage: Binding<Int>, totalPages: Int, @ViewBuilder content: () -> Content) {
        self._currentPage = currentPage
        self.totalPages = totalPages
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .zoomable(
                    minZoomScale: 1.1,
                    doubleTapZoomScale: 2.0,
                    outOfBoundsColor: Color.background
                )
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isOverlayVisible.toggle()
                    }
                }
            
            if isOverlayVisible && inContentRange {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(controller.currentChapter.origin?.manga?.title ?? "Unknown")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text(controller.currentChapter.toString())
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.top)
                    }
                    .foregroundColor(.white)
                    
                    HStack {
                        Button {
                            controller.toggleReaderDirection(context: modelContext)
                        } label: {
                            Image(systemName: controller.settings.readDirection.systemImageName)
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .clipShape(.circle)
                        }
                        
                        Spacer()
                        
                        Button {
                            controller.toggleReaderDirection(context: modelContext)
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .clipShape(.circle)
                        }
                    }
                    .padding(.horizontal, 15)
                    
                    Spacer()
                    
                    VStack {
                        HStack {
                            Button(action: controller.goToPreviousChapter) {
                                Image(systemName: "chevron.left")
                            }
                            .disabled(!controller.canGoBack)
                            .foregroundStyle(Color.white.opacity(controller.canGoBack ? 1 : 0.4))
                            .padding(.horizontal, 15)
                            
                            if totalPages > 1 {
                                Slider(
                                    value: Binding<Double>(
                                        get: { Double(currentPage) },
                                        set: { currentPage = Int($0) }
                                    ),
                                    in: 0...Double(max(0, totalPages - 1)),
                                    step: 1
                                )
                            }
                            else {
                                Spacer()
                            }
                            
                            Button(action: controller.goToNextChapter) {
                                Image(systemName: "chevron.right")
                            }
                            .disabled(!controller.canGoForward)
                            .foregroundStyle(Color.white.opacity(controller.canGoForward ? 1 : 0.4))
                            .padding(.horizontal, 15)
                        }
                        
                        Text("Page \(currentPage + 1) of \(totalPages)")
                            .font(.subheadline)
                            .padding(.bottom)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
            }
        }
        .statusBar(hidden: !isOverlayVisible)
        .edgesIgnoringSafeArea(.bottom)
    }
}

private struct ReaderContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var controller: ReaderControls
    @AppStorage("prefetch") private(set) var PREFETCH_RANGE = 0
    
    @State private var contents = [String]()
    @State private var isLoading = true
    @State private var error: Error?
    
    @State private var isGoingToPreviousChapter = false
    @State private var isGoingToNextChapter = false
    
    @State private var prefetcher: ImagePrefetcher?
    
    @ViewBuilder
    private func LoadingView() -> some View {
        ProgressView("Loading Chapter Content..")
    }
    
    @ViewBuilder
    private func ErrorView(error: Error) -> some View {
        Spacer()
        Button("Back to Home") { dismiss() }
        Spacer()
        Text("Error: \(error.localizedDescription)")
        Spacer()
        Button("Try Again?") { loadChapterContent() }
        Spacer()
    }
    
    @ViewBuilder
    private func EmptyContentView() -> some View {
        Spacer()
        Button("Back to Home") { dismiss() }
        Spacer()
        Text("No Chapter Content for this Chapter.")
        Spacer()
        Button("Try Again?") { loadChapterContent() }
        Spacer()
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
            }
        }
        .onAppear {
            loadChapterContent()
        }
        .onChange(of: controller.currentPage) {
            guard !contents.isEmpty else { return }
            
            prefetchImages()
            updateProgress()
        }
        .onChange(of: controller.currentIndex) { oldValue, newValue in
            isGoingToPreviousChapter = newValue > oldValue
            isGoingToNextChapter = newValue < oldValue
            loadChapterContent()
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
                    
                    // When chapter content gets initially loaded, jump to last page if going to previous chapter or load from the current chapter's progress
                    if isGoingToPreviousChapter {
                        controller.currentPage = contents.count - 1
                    }
                    else if isGoingToNextChapter {
                        controller.currentPage = 0
                    }
                    else {
                        let totalPages = contents.count
                        let currentProgress = max(0.0, min(controller.currentChapter.progress, 1.0))
                        let calculatedPage = Int(Double(totalPages - 1) * currentProgress)
                        let clampedPage = max(0, min(calculatedPage, totalPages - 1))
                        
                        print("Total Pages: \(totalPages)")
                        print("Current Progress: \(currentProgress)")
                        
                        // + 1 since its 0-based counting
                        
                        print("Calculated Page (before clamping): \(calculatedPage + 1)")
                        print("Clamped Page: \(clampedPage + 1)")
                        
                        controller.currentPage = clampedPage
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
        
        print("Prefetching Indexes \(startIndex) to \(endIndex)")
        
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
