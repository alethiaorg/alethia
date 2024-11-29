//
//  ChapterSettingsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 29/11/2024.
//

import SwiftUI
import Reorderable
import Kingfisher

struct ChapterSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    let vm: ChapterListViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Some early space
                Spacer().frame(height: 10)
                
                displaySettingsSection
                
                Group {
                    sourcePrioritySection
                    scanlatorPrioritySection
                }
                .opacity(vm.manga.chapterSettings.showAll ? 0.5 : 1)
                .animation(.easeInOut(duration: 0.25), value: vm.manga.chapterSettings.showAll)
                
                Spacer()
            }
        }
        .autoScrollOnEdges()
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .navigationTitle("Chapter Settings")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var displaySettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DISPLAY SETTINGS")
                .foregroundColor(.secondary)
                .font(.footnote)
                .textCase(.uppercase)
            
            Toggle("Show All Chapters", isOn: Binding(
                get: { vm.manga.chapterSettings.showAll },
                set: { newValue in
                    vm.manga.chapterSettings.showAll = newValue
                    vm.updateChapters()
                }
            ))
            .tint(.green)
            .padding(10)
            .background(Color.tint.opacity(0.5))
            .cornerRadius(8)
            
            Toggle("Show Half Chapters", isOn: Binding(
                get: { vm.manga.chapterSettings.showHalfChapters },
                set: { newValue in
                    vm.manga.chapterSettings.showHalfChapters = newValue
                    vm.updateChapters()
                }
            ))
            .tint(.green)
            .padding(10)
            .background(Color.tint.opacity(0.5))
            .cornerRadius(8)
            .opacity(vm.manga.chapterSettings.showAll ? 0.5 : 1)
            .disabled(vm.manga.chapterSettings.showAll)
            .animation(.easeInOut(duration: 0.25), value: vm.manga.chapterSettings.showAll)
        }
    }
    
    private var sourcePrioritySection: some View {
        VStack(alignment: .leading) {
            Text("SOURCE PRIORITY")
                .foregroundColor(.secondary)
                .font(.footnote)
                .textCase(.uppercase)
                .padding(0)
            
            let originPriorities = vm.manga.chapterSettings.originPriorities.sorted { $0.priority < $1.priority }
            
            ReorderableVStack(originPriorities, onMove: { from, to in
                withAnimation {
                    vm.updateOriginPriority(context: modelContext, from: from, to: to)
                }
            }) { originPriority in
                priorityRow(title: originPriority.origin?.source?.name ?? "Unknown Source",
                            iconURL: originPriority.origin?.source?.icon ?? "",
                            subtitle: originPriority.origin?.source?.host?.name.lowercased() ?? "Unknown Host",
                            count: originPriority.origin?.chapters.count ?? 0)
            }
            .dragDisabled(vm.manga.chapterSettings.showAll)
        }
    }
    
    private var scanlatorPrioritySection: some View {
        VStack(alignment: .leading) {
            Text("SCANLATOR PRIORITY")
                .foregroundColor(.secondary)
                .font(.footnote)
                .textCase(.uppercase)
            
            let scanlatorPriorities = vm.manga.chapterSettings.scanlatorPriorities.sorted { $0.priority < $1.priority }
            ReorderableVStack(scanlatorPriorities, onMove: { from, to in
                withAnimation {
                    vm.updateScanlatorPriority(context: modelContext, from: from, to: to)
                }
            }) { scanlatorPriority in
                priorityRow(title: scanlatorPriority.scanlator,
                            iconURL: scanlatorPriority.source?.icon ?? "",
                            subtitle: "\(scanlatorPriority.source?.host?.name.lowercased() ?? "Unknown Host")/\(scanlatorPriority.source?.name.lowercased() ?? "Unknown Source")")
            }
            .dragDisabled(vm.manga.chapterSettings.showAll)
        }
    }
    
    private func priorityRow(title: String, iconURL: String, subtitle: String, count: Int? = nil) -> some View {
        HStack {
            KFImage(URL(fileURLWithPath: iconURL))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(subtitle)
                    
                    if let count = count {
                        Text("(\(count) Chapters)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .padding()
                .offset(x: 16)
                .dragHandle()
        }
        .padding(15)
        .background(Color.tint.opacity(0.5))
        .cornerRadius(8)
        .padding(.bottom, 10)
    }
}

