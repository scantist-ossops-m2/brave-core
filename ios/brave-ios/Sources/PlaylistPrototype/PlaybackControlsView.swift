// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import DesignSystem
import Foundation
import SwiftUI

extension AnyTransition {
  static var playButtonTransition: AnyTransition {
    .scale.combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7))
  }
}

// FIXME: Delete, move into MediaContentView.PlaybackControlsView
@available(iOS 16.0, *)
struct PlaybackControls: View {
  @ObservedObject var model: PlayerModel

  var body: some View {
    HStack {
      Toggle(isOn: $model.isShuffleEnabled) {
        if model.isShuffleEnabled {
          Image(braveSystemName: "leo.shuffle.toggle-on")
            .transition(.opacity.animation(.linear(duration: 0.1)))
        } else {
          Image(braveSystemName: "leo.shuffle.off")
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
      }
      .toggleStyle(.button)
      Spacer()
      Button {
        Task { await model.seekBackwards() }
      } label: {
        Label("Step Back", braveSystemImage: "leo.rewind.15")
      }
      .buttonStyle(.playbackControl(size: .large))
      .foregroundStyle(Color(braveSystemName: .textPrimary))
      Spacer()
      Toggle(isOn: $model.isPlaying) {
        if model.isPlaying {
          Label("Pause", braveSystemImage: "leo.pause.filled")
            .transition(.playButtonTransition)
        } else {
          Label("Play", braveSystemImage: "leo.play.filled")
            .transition(.playButtonTransition)
        }
      }
      .toggleStyle(.button)
      .accessibilityAddTraits(!model.isPlaying ? .startsMediaSession : [])
      .foregroundStyle(Color(braveSystemName: .textPrimary))
      .buttonStyle(.playbackControl(size: .extraLarge))
      Spacer()
      Button {
        Task { await model.seekForwards() }
      } label: {
        Label("Step Forward", braveSystemImage: "leo.forward.15")
      }
      .buttonStyle(.playbackControl(size: .large))
      .foregroundStyle(Color(braveSystemName: .textPrimary))
      Spacer()
      Button {
        model.repeatMode.cycle()
      } label: {
        // FIXME: Switch to Label's for VoiceOver
        Group {
          switch model.repeatMode {
          case .none:
            Image(braveSystemName: "leo.loop.off")
          case .one:
            Image(braveSystemName: "leo.loop.1")
          case .all:
            Image(braveSystemName: "leo.loop.all")
          }
        }
        .transition(.opacity.animation(.linear(duration: 0.1)))
      }
    }
    .buttonStyle(.playbackControl)
    .foregroundStyle(Color(braveSystemName: .textSecondary))
  }
}
