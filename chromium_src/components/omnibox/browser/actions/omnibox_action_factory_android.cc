// Copyright (c) 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include "components/omnibox/browser/actions/omnibox_action_factory_android.h"

#include "brave/components/omnibox/browser/jni_headers/BraveOmniboxActionFactory_jni.h"
#include "src/components/omnibox/browser/actions/omnibox_action_factory_android.cc"

base::android::ScopedJavaGlobalRef<jobject> BuildLeoAction(
    JNIEnv* env,
    intptr_t instance,
    const std::u16string& hint,
    const std::u16string& accessibility_hint,
    const std::u16string& action_query) {
  return base::android::ScopedJavaGlobalRef(
      Java_BraveOmniboxActionFactory_braveLeoOmniboxAction(
          env, g_java_factory.Get(), instance,
          base::android::ConvertUTF16ToJavaString(env, hint),
          base::android::ConvertUTF16ToJavaString(env, accessibility_hint),
          base::android::ConvertUTF16ToJavaString(env, action_query)));
}
