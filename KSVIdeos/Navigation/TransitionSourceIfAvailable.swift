//
//  TransitionSourceIfAvailable.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera

import SwiftUI

struct TransitionSourceIfAvailable: ViewModifier {
    let id: String
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let ns = namespace {
            content.matchedTransitionSource(id: id, in: ns)
        } else {
            content
        }
    }
}
