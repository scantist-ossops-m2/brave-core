// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import AVKit
import Foundation
import SwiftUI

// FIXME: Add doc
@available(iOS 16.0, *)
struct PlayerView: View {
  var playerModel: PlayerModel

  @State private var isControlsVisible: Bool = false
  @State private var autoHideControlsTask: Task<Void, Error>?
  @State private var dragOffset: CGSize = .zero

  @Environment(\.isFullScreen) private var isFullScreen
  @Environment(\.toggleFullScreen) private var toggleFullScreen

  var body: some View {
    // FIXME: Will likely need a true AVPlayerLayer representable
    VideoPlayer(player: playerModel.player)
      .disabled(true)
      // FIXME: Need device ratio for potrait videos in portrait orientation
      .aspectRatio(16 / 9, contentMode: .fit)
      .offset(x: isFullScreen ? dragOffset.width : 0, y: isFullScreen ? dragOffset.height : 0.0)
      .scaleEffect(
        x: isFullScreen ? 1 - (abs(dragOffset.height) / 1000) : 1,
        y: isFullScreen ? 1 - (abs(dragOffset.height) / 1000) : 1,
        anchor: .center
      )
      .frame(maxWidth: isFullScreen ? .infinity : nil, maxHeight: isFullScreen ? .infinity : nil)
      .ignoresSafeArea(isFullScreen ? .all : [], edges: .bottom)
      // FIXME: Better accessibility copy
      .accessibilityLabel(isFullScreen ? "Tap to toggle controls" : "Media player")
      .accessibilityAddTraits(isFullScreen ? .isButton : [])
      .overlay {
        InlinePlaybackControlsView(model: playerModel)
          .background(
            Color.black.opacity(0.3)
              .allowsHitTesting(false)
              .ignoresSafeArea()
          )
          .opacity(isControlsVisible && isFullScreen ? 1 : 0)
          .accessibilityHidden(isControlsVisible && isFullScreen)
          .background(
            Color.clear
              .contentShape(.rect)
              .simultaneousGesture(
                TapGesture().onEnded { _ in
                  withAnimation(.linear(duration: 0.1)) {
                    isControlsVisible.toggle()
                  }
                }
              )
              .simultaneousGesture(
                DragGesture()
                  .onChanged { value in
                    dragOffset = value.translation
                  }
                  .onEnded { value in
                    let finalOffset = value.predictedEndTranslation
                    if abs(finalOffset.height) > 200 {
                      withAnimation(.snappy) {
                        toggleFullScreen()
                      }
                    }
                    withAnimation(.snappy) {
                      dragOffset = .zero
                    }
                  }
              )
          )
      }
      .onChange(of: isFullScreen) { newValue in
        // Delay showing controls until the animation to present full screen is done, unfortunately
        // there's no way of determining that in SwiftUI, so will just have to wait an arbitrary
        // amount of time.
        withAnimation(.linear(duration: 0.1).delay(newValue ? 0.25 : 0.0)) {
          isControlsVisible = newValue
        }
      }
      .onChange(of: isControlsVisible) { newValue in
        autoHideControlsTask?.cancel()
        if newValue {
          autoHideControlsTask = Task {
            try await Task.sleep(for: .seconds(3))
            withAnimation(.linear(duration: 0.1)) {
              isControlsVisible = false
            }
          }
        }
      }
  }
}

@available(iOS 16.0, *)
extension PlayerView {
  /// Controls shown inside of the PlayerView, typically in fullscreen mode
  struct InlinePlaybackControlsView: View {
    @Environment(\.toggleFullScreen) private var toggleFullScreen

    @ObservedObject var model: PlayerModel

    var body: some View {
      VStack {
        HStack {
          // content speed, sleep timer, shuffle, repeat
          Button {
            model.playbackSpeed.cycle()
          } label: {
            Label("Playback Speed", braveSystemImage: model.playbackSpeed.braveSystemName)
              .transition(.opacity.animation(.linear(duration: 0.1)))
          }
          Spacer()
        }
        Spacer()
        HStack {
          // Seek back, Play/Pause, Seek forwards
        }
        Spacer()
        VStack {
          // scrubber
          HStack {
            // playback time/duration
            Button {
              withAnimation {
                toggleFullScreen()
              }
            } label: {
              Label("Exit Fullscreen", braveSystemImage: "leo.fullscreen.off")
            }
          }
        }
      }
      .buttonStyle(.playbackControl)
      .padding(12)
    }
  }
}
