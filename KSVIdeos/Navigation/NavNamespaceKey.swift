//
//  NavNamespaceKey.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import SwiftUI

private struct NavNamespaceKey: EnvironmentKey {
    static var defaultValue: Namespace.ID? = nil
}

public extension EnvironmentValues {
    var navNamespace: Namespace.ID? {
        get { self[NavNamespaceKey.self] }
        set { self[NavNamespaceKey.self] = newValue }
    }
}
