//
//  ZoomDestinationIfAvailable.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import SwiftUI

struct ZoomDestinationIfAvailable: ViewModifier {
    let id: String
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let ns = namespace {
            content.navigationTransition(.zoom(sourceID: id, in: ns))
        } else {
            content
        }
    }
}
