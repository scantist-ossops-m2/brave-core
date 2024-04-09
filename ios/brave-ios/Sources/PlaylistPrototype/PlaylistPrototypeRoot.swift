// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

@available(iOS 16.0, *)
public struct PlaylistPrototypeRootView: View {
  // FIXME: Will this have to be an ObservedObject instead to handle PiP?
  @StateObject private var playerModel: PlayerModel = .init()

  public init() {}

  public var body: some View {
    NavigationStack {
      PlaylistSplitView(playerModel: playerModel)
        .toolbarBackground(.hidden, for: .navigationBar)
        .observingInterfaceOrientation()
        .creatingRequestGeometryUpdateAction()
        .setUpFullScreenEnvironment()
    }
    .preferredColorScheme(.dark)
    .environment(\.colorScheme, .dark)
  }
}
