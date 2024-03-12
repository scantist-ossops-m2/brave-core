// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

@available(iOS 16.0, *)
public struct PlaylistPrototypeRootView: View {
  @Environment(\.dismiss) private var dismiss

  public init() {}

  public var body: some View {
    NavigationStack {
      PlaylistSplitView()
        .toolbar {
          Button("Done") {
            dismiss()
          }
        }
        .observingInterfaceOrientation()
    }
  }
}
