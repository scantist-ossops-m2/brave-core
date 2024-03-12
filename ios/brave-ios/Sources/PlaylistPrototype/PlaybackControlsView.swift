// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import DesignSystem
import Foundation
import SwiftUI

struct PlaybackControls: View {
  @ObservedObject var model: PlayerModel

  private var playButtonTransition: AnyTransition {
    .scale.combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7))
  }

  var body: some View {
    Group {
      Toggle(isOn: $model.isShuffleEnabled) {
        ZStack {
          Image(braveSystemName: "leo.shuffle.toggle-on")
          Image(braveSystemName: "leo.shuffle.off")
        }
        .accessibilityHidden(true)
        .hidden()
        .overlay {
          if model.isShuffleEnabled {
            Image(braveSystemName: "leo.shuffle.toggle-on")
              .transition(.opacity.animation(.linear(duration: 0.1)))
          } else {
            Image(braveSystemName: "leo.shuffle.off")
              .transition(.opacity.animation(.linear(duration: 0.1)))
          }
        }
      }
      .toggleStyle(.button)
      Spacer()
      Button {
        Task { await model.seekBackwards() }
      } label: {
        Label("Step Back", braveSystemImage: "leo.rewind.15")
      }
      Spacer()
      Toggle(isOn: $model.isPlaying, label: {
        // Maintain the sizes when swapping images
        ZStack {
          Image(braveSystemName: "leo.pause.filled")
          Image(braveSystemName: "leo.play.filled")
        }
        .accessibilityHidden(true)
        .hidden()
        .overlay {
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
      })
      .toggleStyle(.button)
      .foregroundStyle(.primary)
      .font(.title)
      Spacer()
      Button {
        Task { await model.seekForwards() }
      } label: {
        Label("Step Forward", braveSystemImage: "leo.forward.15")
      }
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
    .buttonStyle(.spring(scale: 0.85))
    .labelStyle(.iconOnly)
  }
}

struct LeadingExtraControls: View {
  @Binding var contentSpeed: PlayerModel.PlaybackSpeed

  var body: some View {
    Group {
      Button {
        contentSpeed.cycle()
      } label: {
        Group {
          switch contentSpeed {
          case .normal:
            Image(braveSystemName: "leo.1x")
          case .fast:
            Image(braveSystemName: "leo.1.5x")
          case .faster:
            Image(braveSystemName: "leo.2x")
          }
        }
        .aspectRatio(1, contentMode: .fill)
        .background(Color.red)
        .transition(.opacity.animation(.linear(duration: 0.1)))
      }
    }
    .buttonStyle(.spring(scale: 0.85))
    .labelStyle(.iconOnly)
  }
}

struct TrailingExtraControls: View {
  @Binding var stopPlaybackDate: Date?
  @Binding var isPlaybackStopInfoPresented: Bool

  var body: some View {
    Group {
      if let _ = stopPlaybackDate {
        Button {
          isPlaybackStopInfoPresented = true
        } label: {
          Label("Sleep Timer", braveSystemImage: "leo.sleep.timer")
        }
//        .anchorPreference(key: SleepTimerBoundsPrefKey.self, value: .bounds, transform: { [$0] })
      } else {
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
      }
      Spacer()
      Button { } label: {
        Label("Fullscreen", braveSystemImage: "leo.fullscreen.on")
      }
    }
    .buttonStyle(.spring(scale: 0.85))
    .labelStyle(.iconOnly)
  }
}

#if DEBUG
struct ControlPreview: View {
  @ObservedObject var model: PlayerModel

  var body: some View {
    VStack(spacing: 24) {
      HStack {
        PlaybackControls(model: model)
          .imageScale(.large)
      }
      HStack {
        LeadingExtraControls(contentSpeed: $model.playbackSpeed)
        Spacer()
        TrailingExtraControls(stopPlaybackDate: .constant(nil), isPlaybackStopInfoPresented: .constant(false))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
#Preview {
  ControlPreview(model: .init())
    .padding()
    .environment(\.colorScheme, .dark)
    .background(Color.black)
}
#endif
