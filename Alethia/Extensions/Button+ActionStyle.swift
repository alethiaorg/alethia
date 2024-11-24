//
//  Button+ActionStyle.swift
//  Alethia
//
//  Created by Angelo Carasig on 16/11/2024.
//

import SwiftUI

extension Button {
    func actionButton(_ isActive: Bool) -> some View {
        self.padding(.horizontal, 4)
            .lineLimit(1)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(isActive ? .background : .text)
            .background(isActive ? .text : .tint, in: .rect(cornerRadius: 12, style: .continuous))
            .cornerRadius(12)
    }
}
