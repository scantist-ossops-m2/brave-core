/* Copyright (c) 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

package org.chromium.chrome.browser.crypto_wallet.fragments.onboarding;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import org.chromium.brave_wallet.mojom.BraveWalletP3a;
import org.chromium.brave_wallet.mojom.KeyringService;
import org.chromium.brave_wallet.mojom.OnboardingAction;
import org.chromium.chrome.R;
import org.chromium.chrome.browser.crypto_wallet.adapters.RecoveryPhraseAdapter;
import org.chromium.chrome.browser.crypto_wallet.util.ItemOffsetDecoration;
import org.chromium.chrome.browser.crypto_wallet.util.Utils;

import java.util.List;

public class OnboardingRecoveryPhraseFragment extends BaseOnboardingWalletFragment {
    private static final String IS_ONBOARDING_ARG = "isOnboarding";

    private List<String> mRecoveryPhrases;
    private boolean mIsOnboarding;

    @NonNull
    public static OnboardingRecoveryPhraseFragment newInstance(final boolean isOnboarding) {
        OnboardingRecoveryPhraseFragment fragment = new OnboardingRecoveryPhraseFragment();

        Bundle args = new Bundle();
        args.putBoolean(IS_ONBOARDING_ARG, isOnboarding);
        fragment.setArguments(args);

        return fragment;
    }

    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mIsOnboarding = requireArguments().getBoolean(IS_ONBOARDING_ARG, false);
        return inflater.inflate(R.layout.fragment_recovery_phrase, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        KeyringService keyringService = getKeyringService();
        if (keyringService != null) {
            keyringService.getMnemonicForDefaultKeyring(
                    mOnboardingViewModel.getPassword(),
                    result -> {
                        mRecoveryPhrases = Utils.getRecoveryPhraseAsList(result);
                        setupRecoveryPhraseRecyclerView(view);
                        TextView copyButton = view.findViewById(R.id.btn_copy);
                        assert getActivity() != null;
                        copyButton.setOnClickListener(
                                v -> {
                                    Utils.saveTextToClipboard(
                                            getActivity(),
                                            Utils.getRecoveryPhraseFromList(mRecoveryPhrases),
                                            R.string.text_has_been_copied,
                                            true);
                                });
                    });
        }

        Button recoveryPhraseButton = view.findViewById(R.id.btn_recovery_phrase_continue);
        recoveryPhraseButton.setOnClickListener(
                v -> {
                    BraveWalletP3a braveWalletP3A = getBraveWalletP3A();
                    if (braveWalletP3A != null && mIsOnboarding) {
                        braveWalletP3A.reportOnboardingAction(OnboardingAction.RECOVERY_SETUP);
                    }
                    if (mOnNextPage != null) {
                        mOnNextPage.gotoNextPage();
                    }
                });
        CheckBox recoveryPhraseCheckbox = view.findViewById(R.id.recovery_phrase_checkbox);
        recoveryPhraseCheckbox.setOnCheckedChangeListener(
                (buttonView, isChecked) -> {
                    if (isChecked) {
                        recoveryPhraseButton.setEnabled(true);
                        recoveryPhraseButton.setAlpha(1.0f);
                    } else {
                        recoveryPhraseButton.setEnabled(false);
                        recoveryPhraseButton.setAlpha(0.5f);
                    }
                });
        TextView recoveryPhraseSkipButton = view.findViewById(R.id.btn_recovery_phrase_skip);
        recoveryPhraseSkipButton.setOnClickListener(
                v -> {
                    BraveWalletP3a braveWalletP3A = getBraveWalletP3A();
                    if (braveWalletP3A != null && mIsOnboarding) {
                        braveWalletP3A.reportOnboardingAction(
                                OnboardingAction.COMPLETE_RECOVERY_SKIPPED);
                    }
                    if (mOnNextPage != null) {
                        mOnNextPage.onboardingCompleted();
                    }
                });
    }

    private void setupRecoveryPhraseRecyclerView(@NonNull View view) {
        RecyclerView recyclerView = view.findViewById(R.id.recovery_phrase_recyclerview);
        assert getActivity() != null;
        recyclerView.addItemDecoration(
                new ItemOffsetDecoration(getActivity(), R.dimen.zero_margin));
        GridLayoutManager layoutManager = new GridLayoutManager(getActivity(), 3);
        recyclerView.setLayoutManager(layoutManager);

        RecoveryPhraseAdapter recoveryPhraseAdapter = new RecoveryPhraseAdapter();
        recoveryPhraseAdapter.setRecoveryPhraseList(mRecoveryPhrases);
        recyclerView.setAdapter(recoveryPhraseAdapter);
    }
}
