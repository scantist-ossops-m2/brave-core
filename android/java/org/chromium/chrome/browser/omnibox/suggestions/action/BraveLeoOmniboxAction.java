/* Copyright (c) 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

package org.chromium.chrome.browser.omnibox.suggestions.action;

import android.text.TextUtils;

import androidx.annotation.NonNull;

import org.chromium.chrome.R;
import org.chromium.components.omnibox.action.OmniboxAction;
import org.chromium.components.omnibox.action.OmniboxActionDelegate;
import org.chromium.components.omnibox.action.OmniboxActionId;

public class BraveLeoOmniboxAction extends OmniboxAction {
    static final ChipIcon LEO_ICON =
            new ChipIcon(R.drawable.ic_brave_ai, /* tintWithTextColor= */ true);

    public final @NonNull String actionQuery;

    public BraveLeoOmniboxAction(
            long nativeInstance,
            @NonNull String hint,
            @NonNull String accessibilityHint,
            @NonNull String actionQuery) {
        super(
                OmniboxActionId.OPEN_BRAVE_LEO,
                nativeInstance,
                hint,
                accessibilityHint,
                LEO_ICON);
        assert !TextUtils.isEmpty(actionQuery);
        this.actionQuery = actionQuery;
    }

    @Override
    public void execute(@NonNull OmniboxActionDelegate delegate) {
        org.chromium.base.Log.w("TAG", "!!!execute actionQuery == " + actionQuery);
    }
}
