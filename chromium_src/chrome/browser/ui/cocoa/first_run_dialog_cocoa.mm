/* Copyright (c) 2024 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "chrome/browser/metrics/metrics_reporting_state.h"
// don't change metrics reporting state in first run dialog
#define ChangeMetricsReportingState(STATE) DCHECK(true)
#include "src/chrome/browser/ui/cocoa/first_run_dialog_cocoa.mm"
