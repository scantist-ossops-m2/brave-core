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
    return interfaceOrientation.isPortrait || (idiom == .pad && horizontalSizeClass == .compact)
  }

  /// Whether or not the sidebar is visible
  ///
  /// This is not actually an inverse of whether or not the bottom drawer is visible, since
  /// on iPhone in landscape, we show neither sidebar or drawer.
  private var isSidebarVisible: Bool {
    horizontalSizeClass == .regular && interfaceOrientation.isLandscape
  }

  var body: some View {
    // FIXME: Probably need to account for fullscreen a different way
    // For example, on iPad while using split view, entering full screen on a video probably
    // won't rotate the device, which means we need do still control drawer visibility based
    // on a Binding
    //
    // FIXME: Empty-state instances also affect drawer visibility
    //
    // Maybe can control explicit drawer/sidebar visibility from content view instead
    HStack {
      if isSidebarVisible {
        Text("List Content")
          .frame(width: 320)
        Divider()
      }
      Text("Player View")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
          if isBottomDrawerVisible {
            VStack {
              Divider()
              Text("List Content")
            }
          }
        }
    }
  }
}

// swift-format-ignore
@available(iOS 16.0, *)
#Preview {
  PlaylistSplitView()
    .observingInterfaceOrientation()
}
