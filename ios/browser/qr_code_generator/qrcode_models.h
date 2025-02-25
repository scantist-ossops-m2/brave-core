/* Copyright (c) 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef BRAVE_IOS_BROWSER_QR_CODE_GENERATOR_QRCODE_MODELS_H_
#define BRAVE_IOS_BROWSER_QR_CODE_GENERATOR_QRCODE_MODELS_H_

#include <string>
#include <vector>

#include "components/qr_code_generator/bitmap_generator.h"
#include "components/qr_code_generator/error.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "ui/gfx/geometry/size.h"

// This file is a copy of
// `chrome/services/qrcode_generator/public/mojom/qrcode_generator.mojom` but
// adapted for iOS since it cannot be used directly.

namespace qr_code_generator {
/// Structure for requesting QR Code data or image.
struct GenerateQRCodeOptions {
  /// Data to generate the QR code.
  std::string data;

  /// Whether to render the QR code. If false, provides data back to the caller.
  bool should_render;

  /// Whether to superimpose a Chrome dino over the center of the image.
  bool render_dino;

  /// Style for the individual modules. Does not apply to locators.
  ModuleStyle render_module_style;

  /// Whether the renderer should include rounded corners.
  LocatorStyle render_locator_style;

  GenerateQRCodeOptions();
  GenerateQRCodeOptions(const std::string& data,
                        bool should_render,
                        bool render_dino,
                        ModuleStyle render_module_style,
                        LocatorStyle render_locator_style);
  ~GenerateQRCodeOptions();
};

/// Structure for returning QR Code image data.
struct GenerateQRCodeResult {
  /// Return code stating success or failure.
  Error error_code;

  /// Image data for generated QR code. May be null on error, or if rendering
  /// was not requested.
  SkBitmap bitmap;

  /// QR Code data.
  std::vector<std::uint8_t> data;

  /// 2-D size of |data| in elements. Note |bitmap| will be upscaled, so this
  /// does not represent the returned image size.
  gfx::Size data_size;

  GenerateQRCodeResult();
  GenerateQRCodeResult(Error error_code,
                       const SkBitmap& bitmap,
                       const std::vector<std::uint8_t>& data,
                       const gfx::Size& data_size);
  ~GenerateQRCodeResult();
};

}  // namespace qr_code_generator

#endif  // BRAVE_IOS_BROWSER_QR_CODE_GENERATOR_QRCODE_MODELS_H_
