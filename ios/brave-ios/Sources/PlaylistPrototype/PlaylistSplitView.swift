// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

/// A view which displays playlist content in up to two columns depending on the orientation &
/// size classes.
struct PlaylistSplitView: View {
  @Environment(\.interfaceOrientation) private var interfaceOrientation

  var body: some View {
    Text("Interface Orientation: \(interfaceOrientation.isPortrait ? "Portrait" : interfaceOrientation.isLandscape ? "Landscape" : "Unknown")")
  }
}
