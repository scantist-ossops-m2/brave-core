/* Copyright (c) 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#include "brave/components/brave_wallet/browser/swap_response_parser.h"

#include <optional>
#include <utility>
#include <vector>

#include "base/containers/contains.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/stringprintf.h"
#include "brave/components/brave_wallet/browser/brave_wallet_constants.h"
#include "brave/components/brave_wallet/browser/json_rpc_requests_helper.h"
#include "brave/components/brave_wallet/browser/json_rpc_response_parser.h"
#include "brave/components/brave_wallet/browser/swap_responses.h"
#include "brave/components/brave_wallet/common/hex_utils.h"
#include "brave/components/brave_wallet/common/string_utils.h"
#include "brave/components/json/rs/src/lib.rs.h"

namespace {

constexpr int kSwapValidationErrorCode = 100;
constexpr char kInsufficientAssetLiquidity[] = "INSUFFICIENT_ASSET_LIQUIDITY";
constexpr char kJupiterNoRoutesMessage[] =
    "No routes found for the input and output mints";

}  // namespace

namespace brave_wallet {

namespace zeroex {
namespace {
mojom::ZeroExFeePtr ParseZeroExFee(const base::Value& value) {
  if (value.is_none()) {
    return nullptr;
  }

  if (!value.is_dict()) {
    return nullptr;
  }

  auto zero_ex_fee_value =
      swap_responses::ZeroExFee::FromValue(value.GetDict());
  if (!zero_ex_fee_value) {
    return nullptr;
  }

  auto zero_ex_fee = mojom::ZeroExFee::New();
  zero_ex_fee->fee_type = zero_ex_fee_value->fee_type;
  zero_ex_fee->fee_token = zero_ex_fee_value->fee_token;
  zero_ex_fee->fee_amount = zero_ex_fee_value->fee_amount;
  zero_ex_fee->billing_type = zero_ex_fee_value->billing_type;

  return zero_ex_fee;
}

}  // namespace

mojom::ZeroExQuotePtr ParseQuoteResponse(const base::Value& json_value,
                                         bool expect_transaction_data) {
  // {
  //   "price":"1916.27547998814058355",
  //   "guaranteedPrice":"1935.438234788021989386",
  //   "to":"0xdef1c0ded9bec7f1a1670819833240f027b25eff",
  //   "data":"...",
  //   "value":"0",
  //   "gas":"719000",
  //   "estimatedGas":"719000",
  //   "gasPrice":"26000000000",
  //   "protocolFee":"0",
  //   "minimumProtocolFee":"0",
  //   "buyTokenAddress":"0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
  //   "sellTokenAddress":"0x6b175474e89094c44da98b954eedeac495271d0f",
  //   "buyAmount":"1000000000000000000000",
  //   "sellAmount":"1916275479988140583549706",
  //   "sources":[...],
  //   "allowanceTarget":"0xdef1c0ded9bec7f1a1670819833240f027b25eff",
  //   "sellTokenToEthRate":"1900.44962824532464391",
  //   "buyTokenToEthRate":"1",
  //   "estimatedPriceImpact": "0.7232",
  //   "sources": [
  //     {
  //       "name": "0x",
  //       "proportion": "0",
  //     },
  //     {
  //       "name": "Uniswap_V2",
  //       "proportion": "1",
  //     },
  //     {
  //       "name": "Curve",
  //       "proportion": "0",
  //     }
  //   ],
  //   "fees": {
  //     "zeroExFee": {
  //       "feeType": "volume",
  //       "feeToken": "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063",
  //       "feeAmount": "148470027512868522",
  //       "billingType": "on-chain"
  //     }
  //   }
  // }

  auto swap_response_value =
      swap_responses::SwapResponse0x::FromValue(json_value);
  if (!swap_response_value) {
    return nullptr;
  }

  auto swap_response = mojom::ZeroExQuote::New();
  swap_response->price = swap_response_value->price;

  if (expect_transaction_data) {
    if (!swap_response_value->guaranteed_price) {
      return nullptr;
    }
    swap_response->guaranteed_price = *swap_response_value->guaranteed_price;

    if (!swap_response_value->to) {
      return nullptr;
    }
    swap_response->to = *swap_response_value->to;

    if (!swap_response_value->data) {
      return nullptr;
    }
    swap_response->data = *swap_response_value->data;
  }

  swap_response->value = swap_response_value->value;
  swap_response->gas = swap_response_value->gas;
  swap_response->estimated_gas = swap_response_value->estimated_gas;
  swap_response->gas_price = swap_response_value->gas_price;
  swap_response->protocol_fee = swap_response_value->protocol_fee;
  swap_response->minimum_protocol_fee =
      swap_response_value->minimum_protocol_fee;
  swap_response->buy_token_address = swap_response_value->buy_token_address;
  swap_response->sell_token_address = swap_response_value->sell_token_address;
  swap_response->buy_amount = swap_response_value->buy_amount;
  swap_response->sell_amount = swap_response_value->sell_amount;
  swap_response->allowance_target = swap_response_value->allowance_target;
  swap_response->sell_token_to_eth_rate =
      swap_response_value->sell_token_to_eth_rate;
  swap_response->buy_token_to_eth_rate =
      swap_response_value->buy_token_to_eth_rate;
  swap_response->estimated_price_impact =
      swap_response_value->estimated_price_impact;

  for (const auto& source_value : swap_response_value->sources) {
    swap_response->sources.push_back(
        mojom::ZeroExSource::New(source_value.name, source_value.proportion));
  }

  auto fees = mojom::ZeroExFees::New();
  if (auto zero_ex_fee = ParseZeroExFee(swap_response_value->fees.zero_ex_fee);
      zero_ex_fee) {
    fees->zero_ex_fee = std::move(zero_ex_fee);
  }
  swap_response->fees = std::move(fees);

  return swap_response;
}

mojom::ZeroExErrorPtr ParseErrorResponse(const base::Value& json_value) {
  // https://github.com/0xProject/0x-monorepo/blob/development/packages/json-schemas/schemas/relayer_api_error_response_schema.json
  //
  // {
  // 	"code": 100,
  // 	"reason": "Validation Failed",
  // 	"validationErrors": [{
  // 			"field": "sellAmount",
  // 			"code": 1001,
  // 			"reason": "should match pattern \"^\\d+$\""
  // 		},
  // 		{
  // 			"field": "sellAmount",
  // 			"code": 1001,
  // 			"reason": "should be integer"
  // 		},
  // 		{
  // 			"field": "sellAmount",
  // 			"code": 1001,
  // 			"reason": "should match some schema in anyOf"
  // 		}
  // 	]
  // }

  auto swap_error_response_value =
      swap_responses::SwapErrorResponse0x::FromValue(json_value);
  if (!swap_error_response_value) {
    return nullptr;
  }

  auto result = mojom::ZeroExError::New();
  result->code = swap_error_response_value->code;
  result->reason = swap_error_response_value->reason;

  if (swap_error_response_value->validation_errors) {
    for (auto& error_item : *swap_error_response_value->validation_errors) {
      result->validation_errors.emplace_back(mojom::ZeroExErrorItem::New(
          error_item.field, error_item.code, error_item.reason));
    }
  }
  result->is_insufficient_liquidity = false;
  if (result->code == kSwapValidationErrorCode) {
    for (auto& item : result->validation_errors) {
      if (item->reason == kInsufficientAssetLiquidity) {
        result->is_insufficient_liquidity = true;
      }
    }
  }

  return result;
}

}  // namespace zeroex

namespace jupiter {
mojom::JupiterQuotePtr ParseQuoteResponse(const base::Value& json_value) {
  // {
  //   "inputMint": "So11111111111111111111111111111111111111112",
  //   "inAmount": "1000000",
  //   "outputMint": "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
  //   "outAmount": "781469842",
  //   "otherAmountThreshold": "781391696",
  //   "swapMode": "ExactIn",
  //   "slippageBps": "1",
  //   "platformFee": null,
  //   "priceImpactPct": "0",
  //   "routePlan": [
  //     {
  //       "swapInfo": {
  //         "ammKey": "HCk6LA93xPVsF8g4v6gjkiCd88tLXwZq4eJwiYNHR8da",
  //         "label": "Raydium",
  //         "inputMint": "So11111111111111111111111111111111111111112",
  //         "outputMint": "HhJpBhRRn4g56VsyLuT8DL5Bv31HkXqsrahTTUCZeZg4",
  //         "inAmount": "997500",
  //         "outAmount": "4052482154",
  //         "feeAmount": "2500",
  //         "feeMint": "So11111111111111111111111111111111111111112"
  //       },
  //       "percent": "100"
  //     },
  //     {
  //       "swapInfo": {
  //         "ammKey": "HqrRmb2MbEiTrJS5KXhDzUoKbSLbBXJvhNBGEyDNo9Tr",
  //         "label": "Meteora",
  //         "inputMint": "HhJpBhRRn4g56VsyLuT8DL5Bv31HkXqsrahTTUCZeZg4",
  //         "outputMint": "dipQRV1bWwJbZ3A2wHohXiTZC77CzFGigbFEcvsyMrS",
  //         "inAmount": "4052482154",
  //         "outAmount": "834185227",
  //         "feeAmount": "10131205",
  //         "feeMint": "dipQRV1bWwJbZ3A2wHohXiTZC77CzFGigbFEcvsyMrS"
  //       },
  //       "percent": "100"
  //     },
  //     {
  //       "swapInfo": {
  //         "ammKey": "6shkv2VNBPWVABvShgcGmrv98Z1vR3EcdwND6XUwGoFq",
  //         "label": "Meteora",
  //         "inputMint": "dipQRV1bWwJbZ3A2wHohXiTZC77CzFGigbFEcvsyMrS",
  //         "outputMint": "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
  //         "inAmount": "834185227",
  //         "outAmount": "781469842",
  //         "feeAmount": "2085463",
  //         "feeMint": "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"
  //       },
  //       "percent": "100"
  //     }
  //   ]
  // }
  auto quote_value =
      swap_responses::JupiterQuoteResponse::FromValue(json_value);
  if (!quote_value) {
    return nullptr;
  }

  auto swap_quote = mojom::JupiterQuote::New();
  swap_quote->input_mint = quote_value->input_mint;
  swap_quote->in_amount = quote_value->in_amount;
  swap_quote->output_mint = quote_value->output_mint;
  swap_quote->out_amount = quote_value->out_amount;
  swap_quote->other_amount_threshold = quote_value->other_amount_threshold;
  swap_quote->swap_mode = quote_value->swap_mode;
  swap_quote->slippage_bps = quote_value->slippage_bps;
  swap_quote->price_impact_pct = quote_value->price_impact_pct;

  if (!quote_value->platform_fee.is_none()) {
    if (!quote_value->platform_fee.is_dict()) {
      return nullptr;
    }

    auto platform_fee_value = swap_responses::JupiterPlatformFee::FromValue(
        quote_value->platform_fee.GetDict());

    swap_quote->platform_fee = mojom::JupiterPlatformFee::New();
    swap_quote->platform_fee->amount = platform_fee_value->amount;
    swap_quote->platform_fee->fee_bps = platform_fee_value->fee_bps;
  }

  for (const auto& step_value : quote_value->route_plan) {
    auto step = mojom::JupiterRouteStep::New();
    step->percent = step_value.percent;

    auto swap_info = mojom::JupiterSwapInfo::New();
    swap_info->amm_key = step_value.swap_info.amm_key;
    swap_info->label = step_value.swap_info.label;
    swap_info->input_mint = step_value.swap_info.input_mint;
    swap_info->output_mint = step_value.swap_info.output_mint;
    swap_info->in_amount = step_value.swap_info.in_amount;
    swap_info->out_amount = step_value.swap_info.out_amount;
    swap_info->fee_amount = step_value.swap_info.fee_amount;
    swap_info->fee_mint = step_value.swap_info.fee_mint;
    step->swap_info = std::move(swap_info);

    swap_quote->route_plan.push_back(std::move(step));
  }

  return swap_quote;
}

std::optional<std::string> ParseTransactionResponse(
    const base::Value& json_value) {
  auto value = swap_responses::JupiterSwapTransactions::FromValue(json_value);
  if (!value) {
    return std::nullopt;
  }

  return value->swap_transaction;
}

mojom::JupiterErrorPtr ParseErrorResponse(const base::Value& json_value) {
  auto jupiter_error_response_value =
      swap_responses::JupiterErrorResponse::FromValue(json_value);
  if (!jupiter_error_response_value) {
    return nullptr;
  }

  auto result = mojom::JupiterError::New();
  result->status_code = jupiter_error_response_value->status_code;
  result->error = jupiter_error_response_value->error;
  result->message = jupiter_error_response_value->message;

  result->is_insufficient_liquidity =
      base::Contains(result->message, kJupiterNoRoutesMessage);

  return result;
}
}  // namespace jupiter

// Function to convert all numbers in JSON string to strings.
//
// For sample JSON response, refer to jupiter::ParseQuoteResponse.
std::optional<std::string> ConvertAllNumbersToString(const std::string& json) {
  auto converted_json =
      std::string(json::convert_all_numbers_to_string(json, ""));
  if (converted_json.empty()) {
    return std::nullopt;
  }

  return converted_json;
}

namespace lifi {

namespace {

std::optional<std::string> ChainIdToHex(const std::string& value) {
  // LiFi uses the following two chain ID strings interchangeably for Solana
  // Ref: https://docs.li.fi/li.fi-api/solana/request-examples
  if (value == "SOL" || value == "1151111081099710") {
    return mojom::kSolanaMainnet;
  }

  uint256_t out;
  if (!Base10ValueToUint256(value, &out)) {
    return std::nullopt;
  }

  return Uint256ValueToHex(out);
}

mojom::BlockchainTokenPtr ParseToken(const swap_responses::LiFiToken& value) {
  auto result = mojom::BlockchainToken::New();
  result->name = value.name;
  result->symbol = value.symbol;
  result->logo = value.logo_uri;
  result->contract_address =
      value.address == kLiFiNativeAssetContractAddress ? "" : value.address;

  if (!base::StringToInt(value.decimals, &result->decimals)) {
    return nullptr;
  }

  auto chain_id = ChainIdToHex(value.chain_id);
  if (!chain_id) {
    return nullptr;
  }
  result->chain_id = chain_id.value();

  // LiFi does not return the coin type, so we infer it from the chain ID.
  if (result->chain_id == mojom::kSolanaMainnet) {
    result->coin = mojom::CoinType::SOL;
  } else {
    result->coin = mojom::CoinType::ETH;
  }

  return result;
}

std::optional<mojom::LiFiStepType> ParseStepType(const std::string& value) {
  if (value == "swap") {
    return mojom::LiFiStepType::kSwap;
  }

  if (value == "cross") {
    return mojom::LiFiStepType::kCross;
  }

  if (value == "lifi") {
    return mojom::LiFiStepType::kNative;
  }

  return std::nullopt;
}

mojom::LiFiActionPtr ParseAction(const swap_responses::LiFiAction& value) {
  auto result = mojom::LiFiAction::New();
  result->from_amount = value.from_amount;
  result->from_token = ParseToken(value.from_token);
  result->from_address = value.from_address;

  result->to_token = ParseToken(value.to_token);
  result->to_address = value.to_address;

  result->slippage = value.slippage;
  result->destination_call_data = value.destination_call_data;
  return result;
}

mojom::LiFiStepEstimatePtr ParseEstimate(
    const swap_responses::LiFiEstimate& value) {
  auto result = mojom::LiFiStepEstimate::New();
  result->tool = value.tool;
  result->from_amount = value.from_amount;
  result->to_amount = value.to_amount;
  result->to_amount_min = value.to_amount_min;
  result->approval_address = value.approval_address;

  for (const auto& fee_cost_value : value.fee_costs) {
    auto fee_cost = mojom::LiFiFeeCost::New();
    fee_cost->name = fee_cost_value.name;
    fee_cost->description = fee_cost_value.description;
    fee_cost->percentage = fee_cost_value.percentage;
    fee_cost->token = ParseToken(fee_cost_value.token);
    fee_cost->amount = fee_cost_value.amount;
    fee_cost->included = fee_cost_value.included;
    result->fee_costs.push_back(std::move(fee_cost));
  }

  for (const auto& gas_cost_value : value.gas_costs) {
    auto gas_cost = mojom::LiFiGasCost::New();
    gas_cost->type = gas_cost_value.type;
    gas_cost->estimate = gas_cost_value.estimate;
    gas_cost->limit = gas_cost_value.limit;
    gas_cost->amount = gas_cost_value.amount;
    gas_cost->token = ParseToken(gas_cost_value.token);
    result->gas_costs.push_back(std::move(gas_cost));
  }

  result->execution_duration = value.execution_duration;

  return result;
}

mojom::LiFiStepPtr ParseStep(const swap_responses::LiFiStep& value) {
  auto result = mojom::LiFiStep::New();
  result->id = value.id;

  auto step_type = ParseStepType(value.type);
  if (!step_type) {
    return nullptr;
  }
  result->type = std::move(*step_type);

  result->tool = value.tool;

  auto tool_details = mojom::LiFiToolDetails::New();
  tool_details->key = value.tool_details.key;
  tool_details->name = value.tool_details.name;
  tool_details->logo = value.tool_details.logo_uri;
  result->tool_details = std::move(tool_details);

  result->action = ParseAction(value.action);
  result->estimate = ParseEstimate(value.estimate);

  result->integrator = value.integrator;

  if (!value.included_steps) {
    return result;
  }

  std::vector<mojom::LiFiStepPtr> included_steps = {};
  for (const auto& included_step_value : *value.included_steps) {
    auto included_step = ParseStep(included_step_value);
    if (!included_step) {
      return nullptr;
    }

    included_steps.push_back(std::move(included_step));
  }
  result->included_steps = std::move(included_steps);

  return result;
}

}  // namespace

mojom::LiFiQuotePtr ParseQuoteResponse(const base::Value& json_value) {
  auto value = swap_responses::LiFiQuoteResponse::FromValue(json_value);
  if (!value) {
    return nullptr;
  }

  auto result = mojom::LiFiQuote::New();

  for (const auto& route_value : value->routes) {
    auto route = mojom::LiFiRoute::New();
    route->id = route_value.id;

    auto from_token = ParseToken(route_value.from_token);
    if (!from_token) {
      return nullptr;
    }
    route->from_token = std::move(from_token);
    route->from_amount = route_value.from_amount;
    route->from_address = route_value.from_address;

    auto to_token = ParseToken(route_value.to_token);
    if (!to_token) {
      return nullptr;
    }
    route->to_token = std::move(to_token);

    route->to_amount = route_value.to_amount;
    route->to_amount_min = route_value.to_amount_min;
    route->to_address = route_value.to_address;

    auto insurance = mojom::LiFiInsurance::New();
    insurance->state = route_value.insurance.state;
    insurance->fee_amount_usd = route_value.insurance.fee_amount_usd;
    route->insurance = std::move(insurance);

    for (const auto& step_value : route_value.steps) {
      auto step = ParseStep(step_value);
      if (!step) {
        return nullptr;
      }

      route->steps.push_back(std::move(step));
    }

    route->tags = route_value.tags;
    result->routes.push_back(std::move(route));
  }

  return result;
}

mojom::LiFiTransactionUnionPtr ParseTransactionResponse(
    const base::Value& json_value) {
  auto value = swap_responses::LiFiTransactionResponse::FromValue(json_value);
  if (!value) {
    return nullptr;
  }

  // SOL -> any transfers
  if (!value->transaction_request.data.empty() &&
      !value->transaction_request.from && !value->transaction_request.to &&
      !value->transaction_request.value &&
      !value->transaction_request.gas_price &&
      !value->transaction_request.gas_limit &&
      !value->transaction_request.chain_id) {
    return mojom::LiFiTransactionUnion::NewSolanaTransaction(
        value->transaction_request.data);
  }

  // EVM -> any transfers
  if (value->transaction_request.data.empty() ||

      !value->transaction_request.from ||
      value->transaction_request.from->empty() ||

      !value->transaction_request.to ||
      value->transaction_request.to->empty() ||

      !value->transaction_request.value ||
      value->transaction_request.value->empty() ||

      !value->transaction_request.gas_price ||
      value->transaction_request.gas_price->empty() ||

      !value->transaction_request.gas_limit ||
      value->transaction_request.gas_limit->empty() ||

      !value->transaction_request.chain_id ||
      value->transaction_request.chain_id->empty()) {
    return nullptr;
  }

  auto evm_transaction = mojom::LiFiEVMTransaction::New();
  evm_transaction->data = value->transaction_request.data;
  evm_transaction->from = value->transaction_request.from.value();
  evm_transaction->to = value->transaction_request.to.value();
  evm_transaction->value = value->transaction_request.value.value();
  evm_transaction->gas_price = value->transaction_request.gas_price.value();
  evm_transaction->gas_limit = value->transaction_request.gas_limit.value();

  if (value->transaction_request.chain_id) {
    auto chain_id = ChainIdToHex(value->transaction_request.chain_id.value());
    if (!chain_id) {
      return nullptr;
    }
    evm_transaction->chain_id = chain_id.value();
  }

  return mojom::LiFiTransactionUnion::NewEvmTransaction(
      std::move(evm_transaction));
}

mojom::LiFiErrorPtr ParseErrorResponse(const base::Value& json_value) {
  auto value = swap_responses::LiFiErrorResponse::FromValue(json_value);
  if (!value) {
    return nullptr;
  }

  auto result = mojom::LiFiError::New();
  result->message = value->message;
  return result;
}

}  // namespace lifi

}  // namespace brave_wallet
