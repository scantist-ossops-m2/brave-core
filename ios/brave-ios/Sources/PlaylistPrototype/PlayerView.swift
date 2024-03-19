// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import AVKit

struct PlayerView: View {
  var player: AVPlayer
  var showControlsOnTap: Bool = false

  @State var isControlsVisible: Bool = false

  var body: some View {
    // FIXME: Will likely need a true AVPlayerLayer representable
    VideoPlayer(player: player)
      .disabled(true)
      .aspectRatio(16/9, contentMode: .fit)
      .onTapGesture {
        if showControlsOnTap {
          isControlsVisible.toggle()
        }
      }
      .overlay {
        if isControlsVisible {
          InlinePlaybackControlsView()
        }
      }
  }
}

extension PlayerView {
  /// Controls shown inside of the PlayerView, typically in fullscreen mode
  struct InlinePlaybackControlsView: View {
    var body: some View {
      EmptyView()
    }
  }
}
