/* Copyright (c) 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * you can obtain one at http://mozilla.org/MPL/2.0/. */

#include "components/crx_file/crx_verifier.h"

#include <utility>
#include <vector>

#include "base/no_destructor.h"

namespace {

/*
 * Brave publisher keys that are accepted in addition to upstream's
 * kPublisherKeyHash.
 */

constexpr uint8_t kBraveComponentsKeyHash[] = {
    0x93, 0x74, 0xd6, 0x2a, 0x32, 0x76, 0x74, 0x74, 0xac, 0x99, 0xd9,
    0xc0, 0x55, 0xea, 0xf2, 0x6e, 0x10, 0x7,  0x45, 0x6,  0xb9, 0xd5,
    0x35, 0xc8, 0x35, 0x8,  0x28, 0x97, 0x5f, 0x7a, 0xc1, 0x97};

// If you change this value, then you will likely also need to change the
// associated file crx-private-key.der, which is not in Git.
constexpr uint8_t kBraveBrowserUpdatesKeyHash[] = {
    0xc8, 0x76, 0x54, 0xb1, 0x41, 0x1f, 0x83, 0x9b, 0x53, 0x62, 0xe0,
    0xc7, 0x4c, 0x35, 0x25, 0x0b, 0x63, 0xa3, 0x72, 0x4e, 0x89, 0x20,
    0x1d, 0xb0, 0xbc, 0x21, 0x12, 0xb6, 0xbc, 0x8d, 0x8f, 0x11};

std::vector<uint8_t>& GetBraveComponentsKeyHash() {
  static base::NoDestructor<std::vector<uint8_t>> brave_publisher_key(
      std::begin(kBraveComponentsKeyHash), std::end(kBraveComponentsKeyHash));
  return *brave_publisher_key;
}

std::vector<uint8_t>& GetBraveBrowserUpdatesKeyHash() {
  static base::NoDestructor<std::vector<uint8_t>> brave_browser_updates_key(
      std::begin(kBraveBrowserUpdatesKeyHash),
      std::end(kBraveBrowserUpdatesKeyHash));
  return *brave_browser_updates_key;
}

// Used in the patch in crx_verifier.cc.
bool IsBravePublisher(const std::vector<uint8_t>& key_hash) {
  return key_hash == GetBraveComponentsKeyHash() ||
         key_hash == GetBraveBrowserUpdatesKeyHash();
}

}  // namespace

namespace crx_file {

void SetBraveComponentsKeyHashForTesting(const std::vector<uint8_t>& test_key) {
  GetBraveComponentsKeyHash() = test_key;
}

}  // namespace crx_file

#include "src/components/crx_file/crx_verifier.cc"
