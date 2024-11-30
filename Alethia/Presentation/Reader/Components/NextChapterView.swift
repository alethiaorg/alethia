//
//  NextChapterView.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/11/2024.
//

import SwiftUI

struct NextChapterView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @EnvironmentObject var controller: ReaderControls
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(controller.currentChapter.toString())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Currently Reading")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if controller.canGoForward {
                let nextChapter = controller.chapters[controller.currentIndex - 1]
                
                Button {
                    controller.goToNextChapter()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Chapter")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(nextChapter.toString())
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Published by: \(nextChapter.scanlator)")
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
                Text("There is no next chapter.")
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

