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
      PlaylistSplitView {
        LazyVStack(alignment: .leading) {
          ForEach(0..<10, id: \.self) { _ in
            HStack {
              Color.black.frame(width: 120, height: 90)
              Text("Sidebar Content")
            }
            .padding(12)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      } sidebarHeader: {
        HStack {
          VStack(alignment: .leading) {
            Menu {
              Text("Play Later")
              Text("Play Even Later")
              Text("Never Play")
            } label: {
              Text("Play Later \(Image(braveSystemName: "leo.carat.down"))")
                .fontWeight(.semibold)
                .foregroundStyle(Color(braveSystemName: .textPrimary))
            }
            HStack {
              Text("5 items")
              Text("1h 35m")
              Text("245 MB")
            }
            .font(.caption2)
          }
          Spacer()
          Button { } label: {
            Text("Edit")
              .fontWeight(.semibold)
          }
        }
        .padding()
      } content: {
        // FIXME: Swap out for some sort of container for the selected item (shows different views if its webpage TTS for instance)
        MediaContentView(model: playerModel)
      }
      .observingInterfaceOrientation()
      .creatingRequestGeometryUpdateAction()
      .setUpFullScreenEnvironment()
    }
    .preferredColorScheme(.dark)
    .environment(\.colorScheme, .dark)
    .foregroundStyle(
      Color(braveSystemName: .textPrimary),
      Color(braveSystemName: .textSecondary),
      Color(braveSystemName: .textTertiary)
    )
  }
}

// swift-format-ignore
@available(iOS 16.0, *)
#Preview {
  PlaylistPrototypeRootView()
}
