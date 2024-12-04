//
//  RefreshableScrollView.swift
//  Alethia
//
//  Created by Angelo Carasig on 3/12/2024.
//

import SwiftUI
import Combine

typealias OnRefresh = () async -> Void

enum RefreshState {
    case normal
    case pullDown
    case pullUp
    case refreshHeader
    case refreshFooter
}

final class RefreshableScrollViewModel: ObservableObject {
    let progressViewHeight: CGFloat = 100
    var normalOffsetY: CGFloat = 0
    
    var scrollHeight: CGFloat = 0
    var scrollContentHeight: CGFloat = 0
    
    @Published var refreshFooterCurrHeight: CGFloat = 0
    @Published var refreshHeaderCurrHeight: CGFloat = 0
    @Published var currOffsetY: CGFloat = 0
    @Published var state: RefreshState = .normal
    @Published var isDragging: Bool = false
    
    private var cancellable: Set<AnyCancellable> = []
    
    private var updateProgressViewHeightPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.CombineLatest($currOffsetY, $state)
            .map { currOffsetY, state -> CGFloat in
                
                var _progressViewHeight: CGFloat = currOffsetY - self.normalOffsetY
                if state == .refreshHeader {
                    if _progressViewHeight < self.progressViewHeight {
                        _progressViewHeight = self.progressViewHeight
                    }
                }
                if _progressViewHeight < 0 {
                    _progressViewHeight = 0
                }
                return _progressViewHeight
            }
            .eraseToAnyPublisher()
    }
    
    init() {
        updateProgressViewHeightPublisher
            .dropFirst()
            .removeDuplicates()
            .sink { height in
                DispatchQueue.main.async {
                    if self.state == .pullDown || self.isDragging {
                        self.refreshHeaderCurrHeight = height
                    }
                    else {
                        withAnimation {
                            self.refreshHeaderCurrHeight = height
                        }
                    }
                }
            }
            .store(in: &cancellable)
    }
    
    func onDragEnded() {
        if state == .pullDown {
            if currOffsetY - normalOffsetY > progressViewHeight {
                // Offset is beyond threshold
                state = .refreshHeader
            } else {
                // Reset state
                withAnimation {
                    state = .normal
                }
            }
        } else if state == .pullUp {
            let footerThreshold = (normalOffsetY - currOffsetY) + scrollHeight - scrollContentHeight
            if footerThreshold > progressViewHeight {
                // Offset is beyond threshold
                state = .refreshFooter
            } else {
                withAnimation {
                    state = .normal
                }
            }
        } else {
            // Reset state
            withAnimation {
                state = .normal
            }
        }
    }
    
    func updateOffsets(newMinY: CGFloat, scrollHeight: CGFloat, scrollContentHeight: CGFloat) {
        if currOffsetY != newMinY {
            currOffsetY = newMinY
        }
        
        let _refreshFooterCurrHeight = normalOffsetY - newMinY + scrollHeight - scrollContentHeight
        
        if _refreshFooterCurrHeight > 0 && state != .refreshFooter {
            refreshFooterCurrHeight = _refreshFooterCurrHeight
        }
        
        updateState(refreshFooterCurrHeight: _refreshFooterCurrHeight)
    }
    
    private func updateState(refreshFooterCurrHeight: CGFloat) {
        if isDragging {
            if refreshFooterCurrHeight > progressViewHeight && state == .normal {
                withAnimation {
                    state = .pullUp
                }
            } else if refreshFooterCurrHeight < progressViewHeight && state == .pullUp {
                withAnimation {
                    state = .normal
                }
            } else if currOffsetY - normalOffsetY > progressViewHeight && state == .normal {
                withAnimation {
                    state = .pullDown
                }
            } else if currOffsetY - normalOffsetY < progressViewHeight && state == .pullDown {
                withAnimation {
                    state = .normal
                }
            }
        }
    }
}

struct RefreshableScrollView<Content: View, Header: View, Footer: View>: View {
    @StateObject private var vm: RefreshableScrollViewModel = RefreshableScrollViewModel()
    @State private var refreshTask: Task<Void, Never>? = nil
    
    let content: () -> Content
    let header: (RefreshState) -> Header
    let footer: (RefreshState) -> Footer
    let canRefreshHeader: Bool
    let canRefreshFooter: Bool
    let onRefreshHeader: OnRefresh
    let onRefreshFooter: OnRefresh
    
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping (RefreshState) -> Header,
        @ViewBuilder footer: @escaping (RefreshState) -> Footer,
        canRefreshHeader: Bool,
        canRefreshFooter: Bool,
        onRefreshHeader: @escaping OnRefresh,
        onRefreshFooter: @escaping OnRefresh
    ) {
        self.content = content
        self.header = header
        self.footer = footer
        self.canRefreshHeader = canRefreshHeader
        self.canRefreshFooter = canRefreshFooter
        self.onRefreshHeader = onRefreshHeader
        self.onRefreshFooter = onRefreshFooter
    }
    
    var body: some View {
        ScrollView(.vertical) {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    GeometryReader { proxy -> AnyView in
                        let minY = proxy.frame(in: .global).minY
                        
                        return AnyView(
                            Color.clear
                                .onAppear {
                                    if vm.normalOffsetY == 0 {
                                        vm.normalOffsetY = minY
                                    }
                                }
                                .onChange(of: minY) { _, newMinY in
                                    vm.updateOffsets(newMinY: newMinY, scrollHeight: vm.scrollHeight, scrollContentHeight: vm.scrollContentHeight)
                                }
                                .gesture(DragGesture().onChanged { _ in
                                    vm.isDragging = true
                                }.onEnded { _ in
                                    vm.isDragging = false
                                })
                        )
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 0) {
                        
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            
                            if canRefreshHeader && vm.state == .refreshHeader {
                                ProgressView()
                                    .frame(height: vm.progressViewHeight)
                            }
                            else {
                                header(vm.state)
                                    .frame(height: vm.progressViewHeight)
                                    .opacity(vm.refreshHeaderCurrHeight == 0 ? 0 : 1)
                            }
                        }
                        .transition(.opacity)
                        .frame(height: vm.refreshHeaderCurrHeight)
                        .clipped()
                        .zIndex(999)
                        
                        content()
                    }
                    .overlay {
                        GeometryReader { proxy -> AnyView in
                            let height = proxy.frame(in: .global).height
                            DispatchQueue.main.async {
                                if vm.scrollContentHeight != height {
                                    vm.scrollContentHeight = height
                                }
                            }
                            
                            return AnyView(Color.clear)
                        }
                    }
                }
                .offset(y: vm.state == .refreshFooter ? -vm.progressViewHeight : 0)
                
                VStack {
                    Spacer(minLength: 0)
                    
                    if canRefreshFooter && vm.state == .refreshFooter {
                        ProgressView()
                            .frame(height: vm.progressViewHeight)
                    }
                    else {
                        footer(vm.state)
                            .frame(height: vm.progressViewHeight)
                            .opacity(vm.refreshFooterCurrHeight == 0 ? 0 : 1)
                    }
                }
                .transition(.opacity)
                .frame(height: vm.state == .refreshFooter ? vm.progressViewHeight : vm.refreshFooterCurrHeight)
                .frame(maxWidth: .infinity)
                .clipped()
                .offset(y: vm.state == .refreshFooter ? 0 : vm.refreshFooterCurrHeight)
                .zIndex(999)
            }
        }
        .overlay {
            GeometryReader { proxy -> AnyView in
                let height = proxy.frame(in: .global).height
                DispatchQueue.main.async {
                    if vm.scrollHeight != height {
                        vm.scrollHeight = height
                    }
                }
                
                return AnyView(Color.clear)
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    vm.isDragging = true
                }
                .onEnded { _ in
                    vm.isDragging = false
                    vm.onDragEnded()
                }
        )
        .onDisappear {
            refreshTask?.cancel()
        }
        .onChange(of: vm.state) { _, newState in
            if newState == .refreshHeader, canRefreshHeader {
                refreshTask?.cancel()
                refreshTask = Task {
                    await onRefreshHeader()
                    DispatchQueue.main.async {
                        withAnimation {
                            vm.state = .normal
                        }
                    }
                }
            } else if newState == .refreshFooter, canRefreshFooter {
                refreshTask?.cancel()
                refreshTask = Task {
                    await onRefreshFooter()
                    DispatchQueue.main.async {
                        withAnimation {
                            vm.state = .normal
                        }
                    }
                }
            }
        }
    }
}

private struct ContentView: View {
    @StateObject var vm = RefreshableScrollViewModel()
    let colors: [Color] = [.red, .yellow, .blue, .orange, .cyan]
    
    var body: some View {
        VStack {
            Text("Title")
                .font(.title)
                .foregroundColor(.blue)
                .frame(height: 50)
                .padding()
            
            RefreshableScrollView(
                content: {
                    Contents()
                },
                header: { state in
                    Header(state)
                },
                footer: { state in
                    Footer(state)
                },
                canRefreshHeader: true,
                canRefreshFooter: false,
                onRefreshHeader: {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    print("Hi Up")
                },
                onRefreshFooter: {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    print("Hi Down")
                }
            )
            .contentMargins(0, for: .scrollIndicators)
            .edgesIgnoringSafeArea(.all)
            .defaultScrollAnchor(.top)
        }
    }
    
    @ViewBuilder
    private func Contents() -> some View {
        ZStack {
            ScrollViewReader { proxy in
                VStack{
                    ForEach(1..<20) { i in
                        colors[i%5]
                            .frame(height: 100)
                            .id(i)
                    }
                }
                .onAppear {
                    proxy.scrollTo(3, anchor: .top)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    @ViewBuilder
    private func Header(_ state: RefreshState) -> some View {
        Text("HEADER \(state)")
    }
    
    @ViewBuilder
    private func Footer(_ state: RefreshState) -> some View {
        Text("FOOTER \(state)")
    }
}

#Preview {
    ContentView()
}
