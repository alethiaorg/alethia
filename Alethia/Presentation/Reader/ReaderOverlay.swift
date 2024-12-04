//
//  ReaderOverlay.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/12/2024.
//

import SwiftUI

struct ReaderOverlay<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var controller: ReaderViewModel
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
