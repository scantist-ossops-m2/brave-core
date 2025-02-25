/* Copyright (c) 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#include "brave/components/brave_ads/core/internal/account/user_data/fixed/created_at_timestamp_user_data.h"

#include "base/test/values_test_util.h"
#include "brave/components/brave_ads/core/internal/account/transactions/transaction_info.h"
#include "brave/components/brave_ads/core/internal/account/transactions/transactions_unittest_util.h"
#include "brave/components/brave_ads/core/internal/common/unittest/unittest_base.h"
#include "brave/components/brave_ads/core/internal/common/unittest/unittest_time_converter_util.h"
#include "brave/components/brave_ads/core/internal/settings/settings_unittest_util.h"

// npm run test -- brave_unit_tests --filter=BraveAds*

namespace brave_ads {

class BraveAdsCreatedAtTimestampUserDataTest : public UnitTestBase {
 protected:
  void SetUp() override {
    UnitTestBase::SetUp();

    AdvanceClockTo(TimeFromUTCString("November 18 2020 12:34:56.789"));
  }
};

TEST_F(BraveAdsCreatedAtTimestampUserDataTest,
       BuildCreatedAtTimestampUserDataForRewardsUser) {
  // Arrange
  const TransactionInfo transaction = test::BuildUnreconciledTransaction(
      /*value=*/0.01, ConfirmationType::kViewedImpression,
      /*should_use_random_uuids=*/true);

  // Act & Assert
  EXPECT_EQ(base::test::ParseJsonDict(
                R"(
                    {
                      "createdAtTimestamp": "2020-11-18T12:00:00.000Z"
                    })"),
            BuildCreatedAtTimestampUserData(transaction));
}

TEST_F(BraveAdsCreatedAtTimestampUserDataTest,
       BuildCreatedAtTimestampUserDataForNonRewardsUser) {
  // Arrange
  test::DisableBraveRewards();

  const TransactionInfo transaction = test::BuildUnreconciledTransaction(
      /*value=*/0.01, ConfirmationType::kViewedImpression,
      /*should_use_random_uuids=*/true);

  // Act & Assert
  EXPECT_TRUE(BuildCreatedAtTimestampUserData(transaction).empty());
}

}  // namespace brave_ads
