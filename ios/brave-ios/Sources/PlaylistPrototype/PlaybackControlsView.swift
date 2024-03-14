// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import DesignSystem
import Foundation
import SwiftUI

@available(iOS 16.0, *)
struct PlaybackControls: View {
  @ObservedObject var model: PlayerModel

  private var playButtonTransition: AnyTransition {
    .scale.combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7))
  }

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
            .labelStyle(.iconOnly)
            .transition(playButtonTransition)
        } else {
          Label("Play", braveSystemImage: "leo.play.filled")
            .labelStyle(.iconOnly)
            .transition(playButtonTransition)
        }
      }
      .toggleStyle(.button)
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

@available(iOS 16.0, *)
struct ExtraControls: View {
  @Binding var stopPlaybackDate: Date?
  @Binding var isPlaybackStopInfoPresented: Bool
  @Binding var contentSpeed: PlayerModel.PlaybackSpeed

  var body: some View {
    HStack {
      Button {
        contentSpeed.cycle()
      } label: {
        Image(braveSystemName: contentSpeed.braveSystemName)
          .transition(.opacity.animation(.linear(duration: 0.1)))
      }
      .labelStyle(.iconOnly)
      Spacer()
      Menu {
        Section {
          Button {
            stopPlaybackDate = .now.addingTimeInterval(10 * 60)
          } label: {
            Text("10 minutes")
          }
          Button {
            stopPlaybackDate = .now.addingTimeInterval(20 * 60)
          } label: {
            Text("20 minutes")
          }
          Button {
            stopPlaybackDate = .now.addingTimeInterval(30 * 60)
          } label: {
            Text("30 minutes")
          }
          Button {
            stopPlaybackDate = .now.addingTimeInterval(60 * 60)
          } label: {
            Text("1 hour")
          }
        } header: {
          Text("Stop Playback In…")
        }
      } label: {
        Label("Sleep Timer", braveSystemImage: "leo.sleep.timer")
      }
      Spacer()
      Button {
      } label: {
        Label("Fullscreen", braveSystemImage: "leo.fullscreen.on")
      }
    }
    .buttonStyle(.playbackControl)
    .foregroundStyle(Color(braveSystemName: .textSecondary))
  }
}

#if DEBUG
@available(iOS 16.0, *)
struct ControlPreview: View {
  @ObservedObject var model: PlayerModel
  @State private var currentTime: Duration = .seconds(0)

  var body: some View {
    VStack(spacing: 28) {
      HStack {
        Text("Title")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)
          .lineLimit(1)
        // FIXME: if airplay available (probably from model) {
        Button {

        } label: {
          Label("AirPlay", braveSystemImage: "leo.airplay.video")
        }
        .buttonStyle(.playbackControl)
        // }
      }
      .foregroundStyle(.secondary)
      MediaScrubber(
        currentTime: $currentTime,
        duration: .seconds(1000),
        isScrubbing: .constant(false)
      )
      .tint(Color(braveSystemName: .iconInteractive))
      VStack(spacing: 28) {
        PlaybackControls(model: model)
        ExtraControls(
          stopPlaybackDate: .constant(nil),
          isPlaybackStopInfoPresented: .constant(false),
          contentSpeed: $model.playbackSpeed
        )
      }
      .font(.title3)
    }
    .foregroundStyle(
      Color(braveSystemName: .textPrimary),
      Color(braveSystemName: .textSecondary),
      Color(braveSystemName: .textTertiary)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .dynamicTypeSize(.xSmall...DynamicTypeSize.xxxLarge)  // FIXME: Figure out what to do in AX sizes, maybe second row in PlaybackControls? XXXL may even have issues with DisplayZoom on
  }
}
// swift-format-ignore
@available(iOS 16.0, *)
#Preview {
  ControlPreview(model: .init())
    .padding(24)
    .environment(\.colorScheme, .dark)
    .background(Color(white: 0.1))
}
#endif
