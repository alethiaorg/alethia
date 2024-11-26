//
//  SourceRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct SourceRootView: View {
    @Query private var hosts: [Host]
    @Query private var sources: [Source]
    
    @State private var edit: Bool = false
    @State private var animationId = UUID()
    
    private var pinnedSources: [Source] {
        sources.filter { $0.pinned }
    }
    
    private var unpinnedSources: [Source] {
        sources.filter { !$0.pinned }
    }
    
    var body: some View {
        let noContent: Bool = hosts.isEmpty && sources.isEmpty
        
        NavigationStack {
            VStack {
                if (noContent) {
                    VStack(spacing: 20) {
                        Text("No Sources Available.")
                        Text("(︶︹︺)")
                    }
                }
                else {
                    List {
                        if !pinnedSources.isEmpty {
                            Section(header: Text("Pinned")) {
                                ForEach(pinnedSources) { source in
                                    SourceRow(edit: $edit, source: source, onPinToggle: {
                                        withAnimation(.easeInOut) {
                                            source.pinned.toggle()
                                            animationId = UUID()
                                        }
                                    })
                                }
                            }
                        }
                        
                        Section(header: Text("Sources")) {
                            ForEach(unpinnedSources) { source in
                                SourceRow(edit: $edit, source: source, onPinToggle: {
                                    withAnimation(.easeInOut) {
                                        source.pinned.toggle()
                                        animationId = UUID()
                                    }
                                })
                            }
                        }
                        
                        Section(header: Text("Hosts")) {
                            ForEach(hosts) { host in
                                Text(host.name)
                            }
                        }
                    }
                    .id(animationId)
                }
            }
            .animation(.easeInOut, value: edit)
            .navigationTitle("Sources")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(edit ? "Done" : "Edit") {
                        edit.toggle()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationButton(
                        action: {
                            
                        },
                        destination: {
                            HostAddView()
                        },
                        label: {
                            Image(systemName: "plus")
                        }
                    )
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationButton(
                        action: {
                            
                        },
                        destination: {
                            SearchRootView()
                        },
                        label: {
                            Image(systemName: "magnifyingglass")
                        }
                    )
                }
            }
        }
    }
}

struct SourceRow: View {
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    
    @Binding var edit: Bool
    let source: Source
    var onPinToggle: () -> Void
    
    var body: some View {
        NavigationLink {
            SourceHomeView(source: source)
        } label: {
            HStack {
                KFImage(URL(fileURLWithPath: source.icon))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    .clipped()
                    .padding(.trailing, 10)
                
                VStack(alignment: .leading) {
                    Text(source.name)
                        .font(.headline)
                    Text(source.host?.name ?? "None")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if edit {
                    Button(action: onPinToggle) {
                        Image(systemName: source.pinned ? "pin.fill" : "pin")
                            .foregroundStyle(source.pinned ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .foregroundStyle(.text)
        }
    }
}

#Preview {
    SourceRootView()
}
