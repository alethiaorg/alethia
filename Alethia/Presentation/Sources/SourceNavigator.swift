//
//  SourceNavigator.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import SwiftUI

extension SourceRootView {
    @Observable
    final class Router {
        var navigationPath = NavigationPath()
        
        func navigateTo(route: NavigationRoutes) {
            navigationPath.append(route)
        }
    }
    
    enum NavigationRoutes: Hashable {
        case HostView(_ host: Host)
        case SourceHomeView(_ source: Source)
        case HostAddView
    }
}
