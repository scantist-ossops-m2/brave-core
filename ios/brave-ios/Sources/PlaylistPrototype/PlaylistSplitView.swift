// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

/// A copy of DragGesture.Value set up from UIPanGestureRecognizer instead
private struct UIKitDragGestureValue: Equatable {
  var state: UIPanGestureRecognizer.State
  var location: CGPoint
  var startLocation: CGPoint
  var velocity: CGPoint
  var translation: CGSize {
    .init(width: location.x - startLocation.x, height: location.y - startLocation.y)
  }
  var predictedEndLocation: CGPoint {
    // In SwiftUI's DragGesture.Value, they compute the velocity with the following:
    //     velocity = 4 * (predictedEndLocation - location)
    // Since we have the velocity, we instead compute the predictedEndLocation with:
    //     predictedEndLocation = (velocity / 4) + location
    return .init(
      x: (velocity.x / 4.0) + location.x,
      y: (velocity.y / 4.0) + location.y
    )
  }
  var predictedEndTranslation: CGSize {
    let endLocation = predictedEndLocation
    return .init(width: endLocation.x - startLocation.x, height: endLocation.y - startLocation.y)
  }
  static var empty: UIKitDragGestureValue {
    .init(state: .possible, location: .zero, startLocation: .zero, velocity: .zero)
  }
}

private struct PlaylistDrawerScrollView<Content: View>: UIViewRepresentable {
  @Binding var dragState: UIKitDragGestureValue
  var content: Content
  
  init(
    dragState: Binding<UIKitDragGestureValue>,
    @ViewBuilder content: () -> Content
  ) {
    self._dragState = dragState
    self.content = content()
  }
  
  func makeUIView(context: Context) -> some UIView {
    PlaylistSidebarScrollViewRepresentable(rootView: content, dragState: $dragState)
  }
  
  func updateUIView(_ uiView: UIViewType, context: Context) {
  }

  private class PlaylistSidebarScrollViewRepresentable<Root: View>: UIScrollView {
    @Binding var dragState: UIKitDragGestureValue
    let hostingController: UIHostingController<Root>
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
      fatalError()
    }

    init(rootView: Root, dragState: Binding<UIKitDragGestureValue>) {
      self._dragState = dragState
      hostingController = .init(rootView: rootView)
      super.init(frame: .zero)
      backgroundColor = .clear
      automaticallyAdjustsScrollIndicatorInsets = false
      alwaysBounceVertical = true
      hostingController.view.backgroundColor = .clear
      addSubview(hostingController.view)

      // FIXME: Swap for SnapKit
      hostingController.view.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        contentLayoutGuide.widthAnchor.constraint(equalTo: widthAnchor),
        contentLayoutGuide.topAnchor.constraint(equalTo: hostingController.view.topAnchor),
        contentLayoutGuide.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
        hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
        hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
      ])

      let pan = UIPanGestureRecognizer(target: self, action: #selector(drawerPan(_:)))
      addGestureRecognizer(pan)
      pan.require(toFail: panGestureRecognizer)
    }

    override func safeAreaInsetsDidChange() {
      super.safeAreaInsetsDidChange()
      // For some reason the vertical idicator insets are messed up when the
      // `automaticallyAdjustsScrollIndicatorInsets` property is true so this manually updates
      // them to the correct value
      verticalScrollIndicatorInsets = safeAreaInsets
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
            let scrollView = pan.view as? UIScrollView else {
        return true
      }
      // This will stop the regular scroll view pan from scrolling when the drawer is fully
      // collapsed (smallest "detent") and when you pan downwards from the top (offset = 0) so that
      // the secondary pan can activate and we can shift the drawer up and down.
      if scrollView.bounds.height < 200 {
        return false
      }
      let yVelocity = pan.velocity(in: scrollView).y
      if yVelocity > 0 && scrollView.contentOffset.y == scrollView.contentInset.top {
        return false
      }
      return true
    }

    private var startLocation: CGPoint = .zero
    @objc private func drawerPan(_ pan: UIPanGestureRecognizer) {
      // We get the velocity & location based on the window coordinate system since the local
      // coordinate system will be shifted based on this gesture
      let location = pan.location(in: window)
      if pan.state == .began {
        startLocation = location
        showsVerticalScrollIndicator = false
      }
      dragState = .init(
        state: pan.state,
        location: location,
        startLocation: startLocation,
        velocity: pan.velocity(in: window)
      )
      if pan.state == .ended || pan.state == .cancelled {
        showsVerticalScrollIndicator = true
      }
    }
  }
}


/// A view which displays playlist content in up to two columns depending on the orientation &
/// size classes.
///
/// When the user is using an iPhone or an iPad in portrait (or split view), the sidebar
/// will be displayed as a draggable bottom sheet
@available(iOS 16.0, *)
struct PlaylistSplitView<Sidebar: View, SidebarHeader: View, Content: View>: View {
  @Environment(\.interfaceOrientation) private var interfaceOrientation
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.isFullScreen) private var isFullScreen
  @Environment(\.dismiss) private var dismiss

  var sidebar: Sidebar
  var sidebarHeader: SidebarHeader
  var content: Content

  init(
    @ViewBuilder sidebar: () -> Sidebar,
    @ViewBuilder sidebarHeader: () -> SidebarHeader,
    @ViewBuilder content: () -> Content
  ) {
    self.sidebar = sidebar()
    self.sidebarHeader = sidebarHeader()
    self.content = content()
  }

  /// Whether or not the sidebar is rendered inside of a bottom sheet
  ///
  /// On iPhone:
  ///    - Potrait only; Landscape orientation will enter fullscreen mode
  /// On iPad (Fullscreen):
  ///    - Hide when sidebar is visible, based on horizontal size class being regular
  /// On iPad (Split View):
  ///    - Compact horizontal size class is iPhone layout, even if we're landscape orientation
  private var isSidebarInBottomSheet: Bool {
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
    PlaylistDrawerScrollView(dragState: $sidebarScrollViewDragState) {
      sidebar
    }
    .safeAreaInset(edge: .top, spacing: 0) {
      VStack(spacing: 0) {
        if isSidebarInBottomSheet {
          Capsule()
            .fill(Color.white.opacity(0.2))
            .frame(width: 32, height: 4)
            .padding(.vertical, 8)
        }
        sidebarHeader
        Divider()
      }
      .frame(maxWidth: .infinity)
      .background(Color(braveSystemName: .gray10), ignoresSafeAreaEdges: .bottom)
      .contentShape(.rect)
      // We still need a separate gesture for the header (which is always draggable) since
      // `safeAreaInset(edge:spacing:)` doesn't actually get placed inside of a custom UIScrollView
      // representable.
      .gesture(isSidebarInBottomSheet ? sidebarHeaderDragGesture : nil)
    }
  }

  private func handleBottomSheetDragGestureChanged(translation: CGSize) {
    var value = startingBottomSheetHeight - translation.height
    if value < 120 {
      value = value - _computedOffsetBasedOnRubberBandingResistance(distance: value - 120, dimension: contentSize.height)
    } else if value > contentSize.height {
      value = value + _computedOffsetBasedOnRubberBandingResistance(distance: contentSize.height - value, dimension: contentSize.height)
    }
    bottomSheetHeight = value
  }

  private func handleBottomSheetDragGestureEnded(predictedEndTranslation: CGSize) {
    var endHeight = max(120, startingBottomSheetHeight - predictedEndTranslation.height)
    let videoPlayerHeight = contentSize.width * (9/16)
    if endHeight >= contentSize.height - (videoPlayerHeight / 2) {
      endHeight = contentSize.height
    } else if endHeight >= 200 {
      endHeight = contentSize.height - videoPlayerHeight
    } else {
      endHeight = 120
    }

    withAnimation(.snappy) {
      bottomSheetHeight = endHeight
      startingBottomSheetHeight = bottomSheetHeight
    }
  }

  private var sidebarHeaderDragGesture: some Gesture {
    DragGesture(coordinateSpace: .global)
      .onChanged { value in
        handleBottomSheetDragGestureChanged(translation: value.translation)
      }
      .onEnded { value in
        handleBottomSheetDragGestureEnded(predictedEndTranslation: value.predictedEndTranslation)
      }
  }

  private func _computedOffsetBasedOnRubberBandingResistance(
    distance x: CGFloat,
    constant c: CGFloat = 0.55,
    dimension d: CGFloat
  ) -> CGFloat {
    // f(x, d, c) = (x * d * c) / (d + c * x)
    //
    // where,
    // x – distance from the edge
    // c – constant (UIScrollView uses 0.55)
    // d – dimension, either width or height
    return (x * d * c) / (d + c * x)
  }

  @State private var bottomSheetHeight: CGFloat = 120
  @State private var startingBottomSheetHeight: CGFloat = 120
  @State private var contentSize: CGSize = .zero
  @State private var sidebarScrollViewDragState: UIKitDragGestureValue = .empty

  var body: some View {
    // FIXME: Empty-state instances also affect drawer visibility
    //
    // Maybe can control explicit drawer/sidebar visibility from content view instead
    HStack(spacing: 0) {
      if isSidebarVisible {
        sidebarContents
          .frame(width: 320)
          .background(Color(braveSystemName: .gray10))
        Divider()
          .ignoresSafeArea()
      }
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
          GeometryReader { proxy in
            Color.clear
              .onAppear {
                contentSize = proxy.size
              }
              .onChange(of: proxy.size) { newValue in
                contentSize = newValue
              }
          }
        }
        .overlay(alignment: .bottom) {
          if isSidebarInBottomSheet {
            VStack(spacing: 0) {
              sidebarContents
                .onChange(of: sidebarScrollViewDragState) { value in
                  switch value.state {
                  case .changed:
                    handleBottomSheetDragGestureChanged(translation: value.translation)
                  case .ended, .cancelled:
                    handleBottomSheetDragGestureEnded(predictedEndTranslation: value.predictedEndTranslation)
                  default:
                    break
                  }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .frame(height: bottomSheetHeight)
            .background(Color(braveSystemName: .gray10), ignoresSafeAreaEdges: .bottom)
            .containerShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 10, bottomLeading: 0, bottomTrailing: 0, topTrailing: 10)))
            .ignoresSafeArea(edges: .bottom)
            .transition(.move(edge: .bottom).combined(with: .opacity))
          }
        }
    }
    // FIXME: Drop NavigationStack & real toolbar for a fake toolbar instead
    // would improve animations, layout, and safe area issues with the drawer.
    // on iPad the toolbar background is actually there?
    .toolbar(isFullScreen ? .hidden : .automatic, for: .navigationBar)
    .toolbarBackground(.hidden, for: .navigationBar)
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
