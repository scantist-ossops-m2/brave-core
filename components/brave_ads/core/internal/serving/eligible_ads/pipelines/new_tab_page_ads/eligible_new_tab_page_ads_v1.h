/* Copyright (c) 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#ifndef BRAVE_COMPONENTS_BRAVE_ADS_CORE_INTERNAL_SERVING_ELIGIBLE_ADS_PIPELINES_NEW_TAB_PAGE_ADS_ELIGIBLE_NEW_TAB_PAGE_ADS_V1_H_
#define BRAVE_COMPONENTS_BRAVE_ADS_CORE_INTERNAL_SERVING_ELIGIBLE_ADS_PIPELINES_NEW_TAB_PAGE_ADS_ELIGIBLE_NEW_TAB_PAGE_ADS_V1_H_

#include "base/memory/weak_ptr.h"
#include "brave/components/brave_ads/core/internal/creatives/new_tab_page_ads/creative_new_tab_page_ad_info.h"
#include "brave/components/brave_ads/core/internal/creatives/new_tab_page_ads/creative_new_tab_page_ads_database_table.h"
#include "brave/components/brave_ads/core/internal/history/browsing_history.h"
#include "brave/components/brave_ads/core/internal/segments/segment_alias.h"
#include "brave/components/brave_ads/core/internal/serving/eligible_ads/eligible_ads_callback.h"
#include "brave/components/brave_ads/core/internal/serving/eligible_ads/pipelines/new_tab_page_ads/eligible_new_tab_page_ads_base.h"
#include "brave/components/brave_ads/core/internal/user_engagement/ad_events/ad_event_info.h"
#include "brave/components/brave_ads/core/internal/user_engagement/ad_events/ad_events_database_table.h"

namespace brave_ads {

class AntiTargetingResource;
class SubdivisionTargeting;
struct UserModelInfo;

class EligibleNewTabPageAdsV1 final : public EligibleNewTabPageAdsBase {
 public:
  EligibleNewTabPageAdsV1(const SubdivisionTargeting& subdivision_targeting,
                          const AntiTargetingResource& anti_targeting_resource);
  ~EligibleNewTabPageAdsV1() override;

  void GetForUserModel(
      UserModelInfo user_model,
      EligibleAdsCallback<CreativeNewTabPageAdList> callback) override;

 private:
  void GetEligibleAdsForUserModelCallback(
      UserModelInfo user_model,
      EligibleAdsCallback<CreativeNewTabPageAdList> callback,
      bool success,
      const AdEventList& ad_events);
  void GetEligibleAds(UserModelInfo user_model,
                      const AdEventList& ad_events,
                      EligibleAdsCallback<CreativeNewTabPageAdList> callback,
                      const BrowsingHistoryList& browsing_history);

  void GetForChildSegments(
      UserModelInfo user_model,
      const AdEventList& ad_events,
      const BrowsingHistoryList& browsing_history,
      EligibleAdsCallback<CreativeNewTabPageAdList> callback);
  void GetForChildSegmentsCallback(
      const UserModelInfo& user_model,
      const AdEventList& ad_events,
      const BrowsingHistoryList& browsing_history,
      EligibleAdsCallback<CreativeNewTabPageAdList> callback,
      bool success,
      const SegmentList& segments,
      const CreativeNewTabPageAdList& creative_ads);

  void GetForParentSegments(
      const UserModelInfo& user_model,
      const AdEventList& ad_events,
      const BrowsingHistoryList& browsing_history,
      EligibleAdsCallback<CreativeNewTabPageAdList> callback);
  void GetForParentSegmentsCallback(
      const AdEventList& ad_events,
      const BrowsingHistoryList& browsing_history,
      EligibleAdsCallback<CreativeNewTabPageAdList> callback,
      bool success,
      const SegmentList& segments,
      const CreativeNewTabPageAdList& creative_ads);

  void GetForUntargeted(const AdEventList& ad_events,
                        const BrowsingHistoryList& browsing_history,
                        EligibleAdsCallback<CreativeNewTabPageAdList> callback);
  void GetForUntargetedCallback(
      const AdEventList& ad_events,
      const BrowsingHistoryList& browsing_history,
      EligibleAdsCallback<CreativeNewTabPageAdList> callback,
      bool success,
      const SegmentList& segments,
      const CreativeNewTabPageAdList& creative_ads);

  CreativeNewTabPageAdList FilterCreativeAds(
      const CreativeNewTabPageAdList& creative_ads,
      const AdEventList& ad_events,
      const BrowsingHistoryList& browsing_history);

  const database::table::CreativeNewTabPageAds database_table_;

  const database::table::AdEvents ad_events_database_table_;

  base::WeakPtrFactory<EligibleNewTabPageAdsV1> weak_factory_{this};
};

}  // namespace brave_ads

#endif  // BRAVE_COMPONENTS_BRAVE_ADS_CORE_INTERNAL_SERVING_ELIGIBLE_ADS_PIPELINES_NEW_TAB_PAGE_ADS_ELIGIBLE_NEW_TAB_PAGE_ADS_V1_H_
