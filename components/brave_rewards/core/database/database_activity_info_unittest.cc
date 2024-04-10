/* Copyright (c) 2020 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#include <string>
#include <utility>
#include <vector>

#include "base/test/mock_callback.h"
#include "base/test/task_environment.h"
#include "brave/components/brave_rewards/common/pref_names.h"
#include "brave/components/brave_rewards/core/database/database_activity_info.h"
#include "brave/components/brave_rewards/core/database/database_util.h"
#include "brave/components/brave_rewards/core/rewards_engine_client_mock.h"
#include "brave/components/brave_rewards/core/rewards_engine_mock.h"

// npm run test -- brave_unit_tests --filter=DatabaseActivityInfoTest.*

using ::testing::_;

namespace brave_rewards::internal {
namespace database {

class DatabaseActivityInfoTest : public ::testing::Test {
 protected:
  base::test::TaskEnvironment task_environment_;
  MockRewardsEngine mock_engine_impl_;
  DatabaseActivityInfo activity_{mock_engine_impl_};
};

TEST_F(DatabaseActivityInfoTest, InsertOrUpdateNull) {
  EXPECT_CALL(*mock_engine_impl_.mock_client(), RunDBTransaction(_, _))
      .Times(0);

  base::MockCallback<ResultCallback> callback;
  EXPECT_CALL(callback, Run).Times(1);
  activity_.InsertOrUpdate(nullptr, callback.Get());

  task_environment_.RunUntilIdle();
}

TEST_F(DatabaseActivityInfoTest, InsertOrUpdateOk) {
  EXPECT_CALL(*mock_engine_impl_.mock_client(), RunDBTransaction(_, _))
      .Times(1)
      .WillOnce([](mojom::DBTransactionPtr transaction, auto callback) {
        ASSERT_TRUE(transaction);
        ASSERT_EQ(transaction->commands.size(), 1u);
        ASSERT_EQ(transaction->commands[0]->type, mojom::DBCommand::Type::RUN);
        const std::string query =
            "INSERT OR REPLACE INTO activity_info "
            "(publisher_id, duration, score, percent, "
            "weight, reconcile_stamp, visits) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)";
        ASSERT_EQ(transaction->commands[0]->command, query);
        ASSERT_EQ(transaction->commands[0]->bindings.size(), 7u);
        std::move(callback).Run(db_error_response->Clone());
      });

  auto info = mojom::PublisherInfo::New();
  info->id = "publisher_2";
  info->duration = 10;
  info->score = 1.1;
  info->percent = 100;
  info->reconcile_stamp = 0;
  info->visits = 1;

  base::MockCallback<ResultCallback> callback;
  EXPECT_CALL(callback, Run).Times(1);
  activity_.InsertOrUpdate(std::move(info), callback.Get());

  task_environment_.RunUntilIdle();
}

TEST_F(DatabaseActivityInfoTest, GetRecordsListNull) {
  EXPECT_CALL(*mock_engine_impl_.mock_client(), RunDBTransaction(_, _))
      .Times(0);

  base::MockCallback<GetActivityInfoListCallback> callback;
  EXPECT_CALL(callback, Run).Times(1);
  activity_.GetRecordsList(0, 0, nullptr, callback.Get());

  task_environment_.RunUntilIdle();
}

TEST_F(DatabaseActivityInfoTest, GetRecordsListEmpty) {
  EXPECT_CALL(*mock_engine_impl_.mock_client(), RunDBTransaction(_, _))
      .Times(1)
      .WillOnce([](mojom::DBTransactionPtr transaction, auto callback) {
        ASSERT_TRUE(transaction);
        ASSERT_EQ(transaction->commands.size(), 1u);
        ASSERT_EQ(transaction->commands[0]->type, mojom::DBCommand::Type::READ);
        const std::string query =
            "SELECT ai.publisher_id, ai.duration, ai.score, "
            "ai.percent, ai.weight, spi.status, spi.updated_at, pi.excluded, "
            "pi.name, pi.url, pi.provider, "
            "pi.favIcon, ai.reconcile_stamp, ai.visits "
            "FROM activity_info AS ai "
            "INNER JOIN publisher_info AS pi "
            "ON ai.publisher_id = pi.publisher_id "
            "LEFT JOIN server_publisher_info AS spi "
            "ON spi.publisher_key = pi.publisher_id "
            "WHERE 1 = 1 AND pi.excluded = ? AND spi.status != 0 AND "
            "spi.address != ''";
        ASSERT_EQ(transaction->commands[0]->command, query);
        ASSERT_EQ(transaction->commands[0]->record_bindings.size(), 14u);
        ASSERT_EQ(transaction->commands[0]->bindings.size(), 1u);
        std::move(callback).Run(db_error_response->Clone());
      });

  base::MockCallback<GetActivityInfoListCallback> callback;
  EXPECT_CALL(callback, Run).Times(1);
  activity_.GetRecordsList(0, 0, mojom::ActivityInfoFilter::New(),
                           callback.Get());

  task_environment_.RunUntilIdle();
}

TEST_F(DatabaseActivityInfoTest, GetRecordsListOk) {
  EXPECT_CALL(*mock_engine_impl_.mock_client(), RunDBTransaction(_, _))
      .Times(1)
      .WillOnce([](mojom::DBTransactionPtr transaction, auto callback) {
        ASSERT_TRUE(transaction);
        ASSERT_EQ(transaction->commands.size(), 1u);
        ASSERT_EQ(transaction->commands[0]->type, mojom::DBCommand::Type::READ);
        const std::string query =
            "SELECT ai.publisher_id, ai.duration, ai.score, "
            "ai.percent, ai.weight, spi.status, spi.updated_at, pi.excluded, "
            "pi.name, pi.url, pi.provider, "
            "pi.favIcon, ai.reconcile_stamp, ai.visits "
            "FROM activity_info AS ai "
            "INNER JOIN publisher_info AS pi "
            "ON ai.publisher_id = pi.publisher_id "
            "LEFT JOIN server_publisher_info AS spi "
            "ON spi.publisher_key = pi.publisher_id "
            "WHERE 1 = 1 AND ai.publisher_id = ? AND pi.excluded = ? "
            "AND spi.status != 0 AND spi.address != ''";
        ASSERT_EQ(transaction->commands[0]->command, query);
        ASSERT_EQ(transaction->commands[0]->record_bindings.size(), 14u);
        ASSERT_EQ(transaction->commands[0]->bindings.size(), 2u);
        std::move(callback).Run(db_error_response->Clone());
      });

  auto filter = mojom::ActivityInfoFilter::New();
  filter->id = "publisher_key";

  base::MockCallback<GetActivityInfoListCallback> callback;
  EXPECT_CALL(callback, Run).Times(1);
  activity_.GetRecordsList(0, 0, std::move(filter), callback.Get());

  task_environment_.RunUntilIdle();
}

TEST_F(DatabaseActivityInfoTest, DeleteRecordEmpty) {
  EXPECT_CALL(*mock_engine_impl_.mock_client(), RunDBTransaction(_, _))
      .Times(0);

  base::MockCallback<ResultCallback> callback;
  EXPECT_CALL(callback, Run).Times(1);
  activity_.DeleteRecord("", callback.Get());

  task_environment_.RunUntilIdle();
}

TEST_F(DatabaseActivityInfoTest, DeleteRecordOk) {
  EXPECT_CALL(*mock_engine_impl_.mock_client(),
              GetUserPreferenceValue(prefs::kNextReconcileStamp, _))
      .WillRepeatedly([](const std::string&, auto callback) {
        std::move(callback).Run(base::Value("1597744617"));
      });

  EXPECT_CALL(*mock_engine_impl_.mock_client(), RunDBTransaction(_, _))
      .Times(1)
      .WillOnce([](mojom::DBTransactionPtr transaction, auto callback) {
        ASSERT_TRUE(transaction);
        ASSERT_EQ(transaction->commands.size(), 1u);
        ASSERT_EQ(transaction->commands[0]->type, mojom::DBCommand::Type::RUN);
        const std::string query =
            "DELETE FROM activity_info "
            "WHERE publisher_id = ? AND reconcile_stamp = ?";
        ASSERT_EQ(transaction->commands[0]->command, query);
        ASSERT_EQ(transaction->commands[0]->bindings.size(), 2u);
        std::move(callback).Run(db_error_response->Clone());
      });

  base::MockCallback<ResultCallback> callback;
  EXPECT_CALL(callback, Run).Times(1);
  activity_.DeleteRecord("publisher_key", callback.Get());

  task_environment_.RunUntilIdle();
}

}  // namespace database
}  // namespace brave_rewards::internal
