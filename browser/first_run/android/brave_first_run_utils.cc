/* Copyright (c) 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <jni.h>

#include "brave/build/android/jni_headers/BraveFirstRunUtils_jni.h"
#include "chrome/browser/first_run/first_run.h"

bool IsMetricsReportingOptInAndroid() {
  return first_run::IsMetricsReportingOptIn();
}

static jboolean JNI_BraveFirstRunUtils_IsMetricsReportingOptIn(JNIEnv* env) {
  return IsMetricsReportingOptInAndroid();
}
