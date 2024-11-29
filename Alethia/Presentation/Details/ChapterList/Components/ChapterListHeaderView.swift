//
//  ChapterListHeaderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 29/11/2024.
//

import SwiftUI

struct ChapterListHeaderView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("haptics") private(set) var hapticsEnabled = false
    
    let vm: ChapterListViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chapters")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(vm.unified.count) chapters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    CircleButton(icon: "line.3.horizontal.decrease") { }
                    
                    SortButton()
                }
            }
            
            HStack {
                NavigationLink {
                    if let continueIndex = vm.continueChapterIndex {
                        ReaderRootView(chapters: vm.unified, current: continueIndex)
                    } else {
                        EmptyView()
                    }
                } label: {
                    Text("Continue Reading")
                        .font(.headline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .disabled(vm.continueChapterIndex == nil)
                .buttonStyle(.borderedProminent)
                
                NavigationLink {
                    ChapterSettingsView(vm: vm)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    if hapticsEnabled {
                        Haptics.impact()
                    }
                })
            }
            .frame(height: 44)
        }
    }
    
    @ViewBuilder
    private func SortButton() -> some View {
        Menu {
            let settings = vm.manga.chapterSettings
            
            Section {
                ForEach(ChapterSortOption.allCases, id: \.rawValue) { option in
                    Button(action: {
                        vm.toggleSortOption(context: modelContext, option: option)
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if settings.sortOption == option {
                                Image(systemName: settings.sortDirection == .descending ? "arrow.down" : "arrow.up")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Sort Chapters")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        } label: {
            CircleButton(icon: "arrow.up.arrow.down", isActive: true)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .fixedSize()
    }
}

private struct CircleButton: View {
    let icon: String
    var isActive: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    buttonContent
                }
            } else {
                buttonContent
            }
        }
    }
    
    private var buttonContent: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 40, height: 40)
            .background(isActive ? Color.accentColor : Color.tint.opacity(0.7))
            .foregroundStyle(.white)
            .clipShape(Circle())
            .contentShape(Circle())
    }
}
