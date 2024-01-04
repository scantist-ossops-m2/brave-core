/* Copyright (c) 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

package org.chromium.components.omnibox.action;

import androidx.annotation.NonNull;

import org.jni_zero.CalledByNative;

/** An interface for creation of the BraveOmniboxAction instances. */
public interface BraveOmniboxActionFactory {
    /**
     * Create a new LeoAction.
     *
     * @param actionUri the corresponding action URI/URL
     * @return new instance of an BraveLeoOmniboxAction
     */
    @CalledByNative
    @NonNull
    OmniboxAction braveLeoOmniboxAction(
            long instance,
            @NonNull String hint,
            @NonNull String accessibilityHint,
            @NonNull String actionQuery);
}
