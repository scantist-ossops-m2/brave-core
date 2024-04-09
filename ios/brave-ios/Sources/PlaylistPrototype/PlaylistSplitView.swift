// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

/// A view which displays playlist content in up to two columns depending on the orientation &
/// size classes.
@available(iOS 16.0, *)
struct PlaylistSplitView: View {
  @Environment(\.interfaceOrientation) private var interfaceOrientation
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.isFullScreen) private var isFullScreen
  @Environment(\.dismiss) private var dismiss

  @ObservedObject var playerModel: PlayerModel

  @GestureState private var isDraggingDrawer: Bool = false

  /// Whether or not the bottom drawer is visible
  ///
  /// On iPhone:
  ///    - Potrait only; Landscape orientation will enter fullscreen mode
  /// On iPad (Fullscreen):
  ///    - Hide when sidebar is visible, based on horizontal size class being regular
  /// On iPad (Split View):
  ///    - Compact horizontal size class is iPhone layout, even if we're landscape orientation
  private var isBottomDrawerVisible: Bool {
    let idiom = UIDevice.current.userInterfaceIdiom
    return !isFullScreen
      && (interfaceOrientation.isPortrait || (idiom == .pad && horizontalSizeClass == .compact))
  }

  /// Whether or not the sidebar is visible
  ///
  /// This is not actually an inverse of whether or not the bottom drawer is visible, since
  /// on iPhone in landscape, we show neither sidebar or drawer.
  private var isSidebarVisible: Bool {
    !isFullScreen && horizontalSizeClass == .regular && interfaceOrientation.isLandscape
  }

  var sidebarContents: some View {
    ScrollView {
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
    }
    .scrollDisabled(isDraggingDrawer)
    .safeAreaInset(edge: .top, spacing: 0) {
      VStack(spacing: 0) {
        Capsule()
          .fill(Color.white.opacity(0.2))
          .frame(width: 32, height: 4)
          .padding(.vertical, 8)
        HStack {
          VStack(alignment: .leading) {
            Text("Play Later")
              .fontWeight(.semibold)
            HStack {
              Text("5 items")
              Text("1h 35m")
              Text("245 MB")
            }
            .font(.caption2)
          }
          Spacer()
          Text("Edit")
            .fontWeight(.semibold)
        }
        .padding()
      }
      .frame(maxWidth: .infinity)
      .background(Color(braveSystemName: .gray10))
      .contentShape(.rect)
      .gesture(isBottomDrawerVisible ? drawerDragGesture : nil)
    }
  }

  private var drawerDragGesture: some Gesture {
    DragGesture(coordinateSpace: .global)
      .updating($isDraggingDrawer, body: { _, state, _ in state = true })
      .onChanged { value in
        drawerHeight = max(120, min(screenHeight, initialDrawerHeight - value.translation.height))
      }
      .onEnded { value in
        withAnimation(.snappy) {
          drawerHeight = max(120, min(screenHeight, initialDrawerHeight - value.predictedEndTranslation.height))
          initialDrawerHeight = drawerHeight
        }
      }
  }

  @State private var drawerHeight: CGFloat = 120
  @State private var initialDrawerHeight: CGFloat = 120
  @State private var screenHeight: CGFloat = 0

  var body: some View {
    // FIXME: Empty-state instances also affect drawer visibility
    //
    // Maybe can control explicit drawer/sidebar visibility from content view instead
    HStack {
      if isSidebarVisible {
        sidebarContents
          .frame(width: 320)
        Divider()
      }
      // FIXME: Swap out for some sort of container for the selected item (shows different views if its webpage TTS for instance)
      MediaContentView(model: playerModel)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
          GeometryReader { proxy in
            Color.clear
              .onAppear {
                screenHeight = proxy.size.height
              }
              .onChange(of: proxy.size.height) { newValue in
                screenHeight = newValue
              }
          }
        }
        .overlay(alignment: .bottom) {
          if isBottomDrawerVisible {
            VStack(spacing: 0) {
              sidebarContents
            }
            .frame(height: drawerHeight)
            .background(Color(braveSystemName: .primitiveGray90))
            .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 10, bottomLeading: 0, bottomTrailing: 0, topTrailing: 10)))
          }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    .toolbar(isFullScreen ? .hidden : .automatic, for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button("Done") {
          dismiss()
        }
        .tint(.white)
        .fontWeight(.semibold)
      }
    }
  }
}

// swift-format-ignore
@available(iOS 16.0, *)
#Preview {
  PlaylistSplitView(playerModel: .init())
    .observingInterfaceOrientation()
}
