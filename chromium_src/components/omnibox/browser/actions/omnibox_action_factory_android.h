// Copyright (c) 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#ifndef BRAVE_CHROMIUM_SRC_COMPONENTS_OMNIBOX_BROWSER_ACTIONS_OMNIBOX_ACTION_FACTORY_ANDROID_H_
#define BRAVE_CHROMIUM_SRC_COMPONENTS_OMNIBOX_BROWSER_ACTIONS_OMNIBOX_ACTION_FACTORY_ANDROID_H_

#include "src/components/omnibox/browser/actions/omnibox_action_factory_android.h"

base::android::ScopedJavaGlobalRef<jobject> BuildLeoAction(
    JNIEnv* env,
    intptr_t instance,
    const std::u16string& hint,
    const std::u16string& accessibility_hint,
    const std::u16string& action_query);

#endif  // BRAVE_CHROMIUM_SRC_COMPONENTS_OMNIBOX_BROWSER_ACTIONS_OMNIBOX_ACTION_FACTORY_ANDROID_H_
