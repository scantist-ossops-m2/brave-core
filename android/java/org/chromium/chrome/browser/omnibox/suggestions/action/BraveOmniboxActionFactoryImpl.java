/* Copyright (c) 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

package org.chromium.chrome.browser.omnibox.suggestions.action;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.chromium.components.omnibox.action.BraveOmniboxActionFactory;
import org.chromium.components.omnibox.action.OmniboxAction;

public class BraveOmniboxActionFactoryImpl extends OmniboxActionFactoryImpl implements BraveOmniboxActionFactory {
    public BraveOmniboxActionFactoryImpl() {}

    @Override
    public @Nullable OmniboxAction braveLeoOmniboxAction(
            long nativeInstance,
            @NonNull String hint,
            @NonNull String accessibilityHint,
            @NonNull String actionQuery) {
        return new BraveLeoOmniboxAction(nativeInstance, hint, accessibilityHint, actionQuery);
    }
}
