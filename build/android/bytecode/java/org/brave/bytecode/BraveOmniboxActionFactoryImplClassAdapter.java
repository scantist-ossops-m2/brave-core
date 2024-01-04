/* Copyright (c) 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

package org.brave.bytecode;

import org.objectweb.asm.ClassVisitor;

public class BraveOmniboxActionFactoryImplClassAdapter extends BraveClassVisitor {
    static String sOmniboxActionFactoryImplClassName = "org/chromium/chrome/browser/omnibox/suggestions/action/OmniboxActionFactoryImpl";
    static String sBraveOmniboxActionFactoryImplClassName = "org/chromium/chrome/browser/omnibox/suggestions/action/BraveOmniboxActionFactoryImpl";

    public BraveOmniboxActionFactoryImplClassAdapter(ClassVisitor visitor) {
        super(visitor);

        redirectConstructor(sOmniboxActionFactoryImplClassName, sBraveOmniboxActionFactoryImplClassName);
    }
}
