//
//  SettingsRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import SwiftUI
import Setting

struct SettingsRootView: View {
    @State private var searchText = ""
    
    var body: some View {
        SettingStack {
            SettingPage(title: "Settings") {
                SettingGroup {
                    SettingPage(title: "General") {
                        general
                    }
                    .previewIcon("gearshape.fill")
                }
                
                SettingGroup {
                    SettingPage(title: "Privacy") {
                        notImplemented
                    }
                    .previewIcon("hand.raised.fill", color: .green)
                    
                    SettingPage(title: "Notifications") {
                        notImplemented
                    }
                    .previewIcon("bell.badge.fill", color: .red)
                    
                    SettingPage(title: "Tracking") {
                        notImplemented
                    }
                    .previewIcon("clock.arrow.2.circlepath")
                }
                
                SettingGroup {
                    SettingPage(title: "Library") {
                        notImplemented
                    }
                    .previewIcon("books.vertical.fill", color: .orange)
                    
                    SettingPage(title: "Groups") {
                        notImplemented
                    }
                    .previewIcon("rectangle.3.group.fill", color: .red)
                }
                
                SettingGroup {
                    SettingPage(title: "Sources") {
                        notImplemented
                    }
                    .previewIcon("cube.box.fill", color: .purple)
                    
                    SettingPage(title: "Reader") {
                        reader
                    }
                    .previewIcon("book.fill", color: .orange)
                    
                    SettingPage(title: "Storage") {
                        notImplemented
                    }
                    .previewIcon("externaldrive.fill", color: .teal)
                }
                
                SettingGroup {
                    SettingPage(title: "Backups") {
                        notImplemented
                    }
                    .previewIcon("hand.raised.fill", color: .green)
                    
                    SettingPage(title: "About") {
                        about
                    }
                    .previewIcon("hand.raised.fill", color: .appPurple)
                }
            }
        }
    }
    
    @SettingBuilder var notImplemented: some Setting {
        SettingText(title: "Not Yet Implemented!")
    }
    
    @AppStorage("haptics") private var haptics = true
    @SettingBuilder var general: some Setting {
        SettingGroup(header: "Controls") {
            SettingToggle(title: "Allow Custom Haptic Feedback", isOn: $haptics)
        }
    }
    
    @AppStorage("prefetch") private var prefetch = 0
    @SettingBuilder var reader: some Setting {
        SettingGroup {
            SettingCustomView {
                HStack {
                    Text("Pages To Prefetch")
                    Spacer()
                    HStack(spacing: 15) {
                        Button {
                            withAnimation {
                                prefetch = max(0, prefetch - 1)
                                if haptics {
                                    Haptics.impact(style: .light)
                                }
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(prefetch == 0 ? .tint : .gray)
                                .imageScale(.large)
                                .animation(.easeInOut(duration: 0.2), value: prefetch)
                        }
                        .disabled(prefetch == 0)
                        
                        Text("\(prefetch)")
                            .frame(minWidth: 30)
                            .font(.headline)
                        
                        Button{
                            withAnimation {
                                prefetch += 1
                                if haptics {
                                    Haptics.impact(style: .light)
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.gray)
                                .imageScale(.large)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
        }
    }
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "Version \(version) (\(build))"
        }
        return "Version Unknown"
    }
    
    @SettingBuilder
    private var about: some Setting {
        SettingGroup {
            SettingCustomView {
                HStack {
                    Text("App Version")
                    
                    Spacer()
                    
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
        }
    }
}

#Preview {
    SettingsRootView()
}
