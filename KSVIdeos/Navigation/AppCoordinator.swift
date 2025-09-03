//
//  AppCoordinator.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Combine
import Foundation

enum AppRoute: Hashable {
    case videoDetail(VideoItemUI)
}

final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []
    
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func reset() {
        path = []
    }
}

