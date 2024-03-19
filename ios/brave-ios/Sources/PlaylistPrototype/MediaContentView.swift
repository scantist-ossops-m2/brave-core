// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import AVKit

/// The view shown when the user is playing video or audio
@available(iOS 16.0, *)
struct MediaContentView: View {
  @ObservedObject var model: PlayerModel

  @Environment(\.interfaceOrientation) private var interfaceOrientation

  private var isFullScreen: Bool {
    interfaceOrientation.isLandscape && UIDevice.current.userInterfaceIdiom == .phone
  }

  var body: some View {
    VStack {
      PlayerView(player: model.player)
      if !isFullScreen {
        PlaybackControlsView(model: model)
          .padding(24)
      }
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .background(isFullScreen ? .black : Color(braveSystemName: .containerBackground))
    .environment(\.colorScheme, .dark)
  }
}

@available(iOS 16.0, *)
extension MediaContentView {
  struct PlaybackControlsView: View {
    @ObservedObject var model: PlayerModel

    @State private var currentTime: TimeInterval = 0
    @State private var isScrubbing: Bool = false
    @State private var resumePlayingAfterScrub: Bool = false

    var body: some View {
      VStack(spacing: 28) {
        HStack {
          Text("Selected Item Title")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
          if model.isPictureInPictureSupported {
            Button {

            } label: {
              Label("AirPlay", braveSystemImage: "leo.airplay.video")
            }
            .buttonStyle(.playbackControl)
            .transition(.opacity.animation(.default))
          }
        }
        .foregroundStyle(.secondary)
        MediaScrubber(
          currentTime: Binding(
            get: { .seconds(currentTime) },
            set: { newValue in
              Task { await model.seek(to: TimeInterval(newValue.components.seconds)) }
            }
          ),
          duration: .seconds(model.duration),
          isScrubbing: $isScrubbing
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
      // FIXME: Figure out what to do in AX sizes, maybe second row in PlaybackControls?
      // XXXL may even have issues with DisplayZoom on
      .dynamicTypeSize(.xSmall...DynamicTypeSize.xxxLarge)
      .onChange(of: isScrubbing) { newValue in
        if newValue {
          resumePlayingAfterScrub = model.isPlaying
          model.pause()
        } else {
          if resumePlayingAfterScrub {
            model.play()
          }
        }
      }
      .task {
        for await currentTime in model.currentTimeStream {
          self.currentTime = currentTime
        }
      }
    }
  }
}
