// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import AVKit
import Foundation
import SwiftUI

/// The view shown when the user is playing video or audio
@available(iOS 16.0, *)
struct MediaContentView: View {
  @ObservedObject var model: PlayerModel

  @Environment(\.interfaceOrientation) private var interfaceOrientation
  @Environment(\.isFullScreen) private var isFullScreen
  @Environment(\.toggleFullScreen) private var toggleFullScreen
  @Environment(\.requestGeometryUpdate) private var requestGeometryUpdate

  var body: some View {
    VStack {
      PlayerView(playerModel: model)
        .zIndex(1)
      if !isFullScreen {
        PlaybackControlsView(model: model)
          .padding(24)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isFullScreen ? .center : .top)
    //    .background(isFullScreen ? .black : Color(braveSystemName: .containerBackground))
    .background(Color(braveSystemName: .containerBackground))
    .onChange(of: isFullScreen) { newValue in
      // Automatically rotate the device orientation on iPhones when the video is not portrait
      if UIDevice.current.userInterfaceIdiom == .phone, !model.isPortraitVideo {
        //        requestGeometryUpdate(orientation: newValue ? .landscapeLeft : .portrait)
      }
    }
    .onChange(of: interfaceOrientation) { newValue in
      if UIDevice.current.userInterfaceIdiom == .phone {
        toggleFullScreen(explicitFullScreenMode: newValue.isLandscape)
      }
    }
    .persistentSystemOverlays(isFullScreen ? .hidden : .automatic)
    .defersSystemGestures(on: isFullScreen ? .all : [])
  }
}

@available(iOS 16.0, *)
extension MediaContentView {
  struct PlaybackControlsView: View {
    @ObservedObject var model: PlayerModel

    @State private var currentTime: TimeInterval = 0
    @State private var isScrubbing: Bool = false
    @State private var resumePlayingAfterScrub: Bool = false

    @Environment(\.toggleFullScreen) private var toggleFullScreen

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
          HStack {
            Button {
              model.playbackSpeed.cycle()
            } label: {
              Label("Playback Speed", braveSystemImage: model.playbackSpeed.braveSystemName)
                .transition(.opacity.animation(.linear(duration: 0.1)))
            }
            Spacer()
            Menu {
              Section {
                Button {
                  //                  stopPlaybackDate = .now.addingTimeInterval(10 * 60)
                } label: {
                  Text("10 minutes")
                }
                Button {
                  //                  stopPlaybackDate = .now.addingTimeInterval(20 * 60)
                } label: {
                  Text("20 minutes")
                }
                Button {
                  //                  stopPlaybackDate = .now.addingTimeInterval(30 * 60)
                } label: {
                  Text("30 minutes")
                }
                Button {
                  //                  stopPlaybackDate = .now.addingTimeInterval(60 * 60)
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
              withAnimation {
                toggleFullScreen()
              }
            } label: {
              Label("Fullscreen", braveSystemImage: "leo.fullscreen.on")
            }
          }
          .buttonStyle(.playbackControl)
          .foregroundStyle(.secondary)
        }
        .font(.title3)
      }
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
