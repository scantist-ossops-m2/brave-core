/* Copyright (c) 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#include "brave/components/omnibox/browser/leo_action.h"

#if BUILDFLAG(IS_ANDROID)
#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/strings/utf_string_conversions.h"
#include "components/grit/brave_components_strings.h"
#include "components/omnibox/browser/actions/omnibox_action_factory_android.h"
#include "url/android/gurl_android.h"
#include "ui/base/l10n/l10n_util.h"
#endif

LeoAction::LeoAction(const std::u16string& query)
    : OmniboxAction({}, {}), query_(query) {}

void LeoAction::Execute(ExecutionContext& context) const {
  context.client_->OpenLeo(query_);
}

#if BUILDFLAG(IS_ANDROID)
base::android::ScopedJavaLocalRef<jobject>
LeoAction::GetOrCreateJavaObject(JNIEnv* env) const {
  if (!j_omnibox_action_) {
    j_omnibox_action_.Reset(BuildLeoAction(
        env, reinterpret_cast<intptr_t>(this),
      l10n_util::GetStringUTF16(IDS_OMNIBOX_ASK_LEO_DESCRIPTION),
      l10n_util::GetStringUTF16(IDS_OMNIBOX_ASK_LEO_DESCRIPTION), query_));
  }
  return base::android::ScopedJavaLocalRef<jobject>(j_omnibox_action_);
}
#endif

LeoAction::~LeoAction() = default;
