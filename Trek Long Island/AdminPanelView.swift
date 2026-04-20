// Copyright Bryan Carroll. All rights reserved.
//
//  AdminPanelView.swift
//  Trek Long Island
//
//  Legacy entry point kept for compatibility.
//  All operator/master workflows now route through Ops Center.
//

import SwiftUI

@MainActor
struct AdminPanelView: View {
    var body: some View {
        OpsCenterView()
    }
}

#Preview {
    NavigationStack {
        AdminPanelView()
    }
}
