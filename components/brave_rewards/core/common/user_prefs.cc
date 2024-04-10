/* Copyright (c) 2024 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#include "brave/components/brave_rewards/core/common/user_prefs.h"

#include <utility>

#include "base/json/values_util.h"
#include "base/strings/string_number_conversions.h"

namespace brave_rewards::internal {

UserPrefs::UserPrefs(RewardsEngine& engine) : RewardsEngineHelper(engine) {}

UserPrefs::~UserPrefs() = default;

void UserPrefs::SetBoolean(const std::string& path, bool value) {
  Set(path, base::Value(value));
}

bool UserPrefs::GetBoolean(const std::string& path) {
  return GetValue(path).GetIfBool().value_or(false);
}

void UserPrefs::SetInteger(const std::string& path, int value) {
  Set(path, base::Value(value));
}

int UserPrefs::GetInteger(const std::string& path) {
  return GetValue(path).GetIfInt().value_or(0);
}

void UserPrefs::SetDouble(const std::string& path, double value) {
  Set(path, base::Value(value));
}

double UserPrefs::GetDouble(const std::string& path) {
  return GetValue(path).GetIfDouble().value_or(0);
}

void UserPrefs::SetString(const std::string& path, std::string_view value) {
  Set(path, base::Value(value));
}

const std::string& UserPrefs::GetString(const std::string& path) {
  SetDefault(path, base::Value(""));
  return GetValue(path).GetString();
}

void UserPrefs::Set(const std::string& path, const base::Value& value) {
  client().SetUserPreferenceValue(path, value.Clone());
  values_[path] = value.Clone();
}

const base::Value& UserPrefs::GetValue(const std::string& path) {
  base::Value value;
  client().GetUserPreferenceValue(path, &value);
  if (!value.is_none()) {
    values_[path] = std::move(value);
  }
  return values_[path];
}

void UserPrefs::SetDict(const std::string& path, base::Value::Dict dict) {
  Set(path, base::Value(std::move(dict)));
}

const base::Value::Dict& UserPrefs::GetDict(const std::string& path) {
  SetDefault(path, base::Value(base::Value::Dict()));
  return GetValue(path).GetDict();
}

void UserPrefs::SetInt64(const std::string& path, int64_t value) {
  Set(path, base::Value(base::NumberToString(value)));
}

int64_t UserPrefs::GetInt64(const std::string& path) {
  SetDefault(path, base::Value("0"));
  return base::ValueToInt64(GetValue(path)).value_or(0);
}

void UserPrefs::SetUint64(const std::string& path, uint64_t value) {
  Set(path, base::Value(base::NumberToString(value)));
}

uint64_t UserPrefs::GetUint64(const std::string& path) {
  SetDefault(path, base::Value("0"));
  uint64_t result;
  base::StringToUint64(GetValue(path).GetString(), &result);
  return result;
}

void UserPrefs::SetTime(const std::string& path, base::Time value) {
  Set(path, base::TimeToValue(value));
}

base::Time UserPrefs::GetTime(const std::string& path) {
  return base::ValueToTime(GetValue(path)).value_or(base::Time());
}

void UserPrefs::SetTimeDelta(const std::string& path, base::TimeDelta value) {
  Set(path, base::TimeDeltaToValue(value));
}

base::TimeDelta UserPrefs::GetTimeDelta(const std::string& path) {
  return base::ValueToTimeDelta(GetValue(path)).value_or(base::TimeDelta());
}

void UserPrefs::ClearPref(const std::string& path) {
  client().ClearUserPreferenceValue(path);
}

void UserPrefs::SetDefault(const std::string& path, base::Value value) {
  // In some environments (e.g. unit tests) the client might not provide a
  // default value. Setting a default before getting the value ensures that we
  // have the correct type.
  base::Value& current = values_[path];
  if (current.is_none()) {
    current = std::move(value);
  }
}

}  // namespace brave_rewards::internal
