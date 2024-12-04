//
//  PreviousChapterView.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/11/2024.
//

import SwiftUI

struct PreviousChapterView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @EnvironmentObject var vm: ReaderViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(vm.currentChapter.toString())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Currently Reading")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if vm.canGoBack {
                let prevChapter = vm.chapters[vm.currentIndex + 1]
                
                Button {
                    vm.goToPreviousChapter()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Previous Chapter")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prevChapter.toString())
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Published by \(prevChapter.scanlator)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.tint.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                Text("There is no previous chapter.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Exit")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            .highPriorityGesture(
                TapGesture().onEnded {
                    if hapticsEnabled {
                        Haptics.impact()
                    }
                    dismiss()
                }
            )
            
            Spacer()
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}
