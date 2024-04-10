// Copyright (c) 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include "brave/ios/browser/ui/webui/wallet/brave_wallet_page_ui.h"

#include "brave/components/brave_wallet_page/resources/grit/brave_wallet_deposit_page_generated_map.h"
#include "brave/components/brave_wallet_page/resources/grit/brave_wallet_fund_wallet_page_generated_map.h"
#include "brave/components/brave_wallet_page/resources/grit/brave_wallet_send_page_generated_map.h"
#include "brave/components/brave_wallet_page/resources/grit/brave_wallet_swap_page_generated_map.h"

// #include "brave/ios/browser/ui/webui/brave_webui_source.h"

#include <string>
#include <utility>

#include "base/command_line.h"
#include "base/files/file_path.h"
#include "brave/components/brave_wallet/browser/asset_ratio_service.h"
#include "brave/components/brave_wallet/browser/blockchain_registry.h"
#include "brave/components/brave_wallet/browser/brave_wallet_constants.h"
#include "brave/components/brave_wallet/browser/brave_wallet_ipfs_service.h"
#include "brave/components/brave_wallet/browser/brave_wallet_service.h"
#include "brave/components/brave_wallet/browser/json_rpc_service.h"
#include "brave/components/brave_wallet/browser/keyring_service.h"
#include "brave/components/brave_wallet/browser/simulation_service.h"
#include "brave/components/brave_wallet/browser/swap_service.h"
#include "brave/components/brave_wallet/browser/tx_service.h"
#include "brave/components/brave_wallet_page/resources/grit/brave_wallet_page_generated_map.h"
#include "brave/components/constants/webui_url_constants.h"
#include "brave/components/ipfs/buildflags/buildflags.h"
#include "brave/components/l10n/common/localization_util.h"
#include "brave/ios/browser/brave_wallet/asset_ratio_service_factory.h"
#include "brave/ios/browser/brave_wallet/bitcoin_wallet_service_factory.h"
#include "brave/ios/browser/brave_wallet/brave_wallet_ipfs_service_factory.h"
#include "brave/ios/browser/brave_wallet/brave_wallet_service_factory.h"
#include "brave/ios/browser/brave_wallet/json_rpc_service_factory.h"
#include "brave/ios/browser/brave_wallet/keyring_service_factory.h"
#include "brave/ios/browser/brave_wallet/swap_service_factory.h"
#include "brave/ios/browser/brave_wallet/tx_service_factory.h"
#include "brave/ios/browser/brave_wallet/zcash_wallet_service_factory.h"
#include "brave/ios/browser/ui/webui/wallet/wallet_common_ui.h"
#include "ios/chrome/browser/shared/model/browser_state/chrome_browser_state.h"

#include "components/grit/brave_components_resources.h"
#include "components/grit/brave_components_strings.h"
#import "ios/web/public/web_state.h"
#include "ios/web/public/webui/url_data_source_ios.h"
#import "ios/web/public/webui/web_ui_ios.h"
#import "ios/web/public/webui/web_ui_ios_data_source.h"
#import "ios/web/public/webui/web_ui_ios_message_handler.h"
#include "ui/base/accelerators/accelerator.h"
#include "ui/base/webui/web_ui_util.h"

namespace {

web::WebUIIOSDataSource* CreateAndAddWebUIDataSource(
    web::WebUIIOS* web_ui,
    const std::string& name,
    const webui::ResourcePath* resource_map,
    std::size_t resource_map_size,
    int html_resource_id) {
  web::WebUIIOSDataSource* source = web::WebUIIOSDataSource::Create(name);
  web::WebUIIOSDataSource::Add(ChromeBrowserState::FromWebUIIOS(web_ui),
                               source);
  source->UseStringsJs();

  // Add required resources.
  source->AddResourcePaths(base::make_span(resource_map, resource_map_size));
  source->SetDefaultResource(html_resource_id);
  return source;
}

}  // namespace

BraveWalletPageUI::BraveWalletPageUI(web::WebUIIOS* web_ui, const GURL& url)
    : web::WebUIIOSController(web_ui, url.host()) {
  web::WebUIIOSDataSource* source;
  if (url.path() == "/swap") {
    source = CreateAndAddWebUIDataSource(
        web_ui, url.host(), kBraveWalletSwapPageGenerated,
        kBraveWalletSwapPageGeneratedSize, IDR_BRAVE_WALLET_SWAP_PAGE_HTML);
  } else if (url.path() == "/send") {
    source = CreateAndAddWebUIDataSource(
        web_ui, url.host(), kBraveWalletSendPageGenerated,
        kBraveWalletSendPageGeneratedSize, IDR_BRAVE_WALLET_SEND_PAGE_HTML);
  } else {
    NOTREACHED() << "Failed to find page resources for:" << url.path();
  }

  for (const auto& str : brave_wallet::kLocalizedStrings) {
    std::u16string l10n_str =
        brave_l10n::GetLocalizedResourceUTF16String(str.id);
    source->AddString(str.name, l10n_str);
  }

  source->AddBoolean("isAndroid", true);
  source->AddBoolean("isIOS", true);

  source->AddString("braveWalletLedgerBridgeUrl", kUntrustedLedgerURL);
  source->AddString("braveWalletTrezorBridgeUrl", kUntrustedTrezorURL);
  source->AddString("braveWalletNftBridgeUrl", kUntrustedNftURL);
  source->AddString("braveWalletLineChartBridgeUrl", kUntrustedLineChartURL);
  source->AddString("braveWalletMarketUiBridgeUrl", kUntrustedMarketURL);
  source->AddBoolean(brave_wallet::mojom::kP3ACountTestNetworksLoadTimeKey,
                     base::CommandLine::ForCurrentProcess()->HasSwitch(
                         brave_wallet::mojom::kP3ACountTestNetworksSwitch));

  brave_wallet::AddBlockchainTokenImageSource(
      ChromeBrowserState::FromWebUIIOS(web_ui));

  web_ui->GetWebState()->GetInterfaceBinderForMainFrame()->AddInterface(
      base::BindRepeating(&BraveWalletPageUI::BindInterface,
                          base::Unretained(this)));
}

BraveWalletPageUI::~BraveWalletPageUI() {
  web_ui()->GetWebState()->GetInterfaceBinderForMainFrame()->RemoveInterface(
      "brave_wallet.mojom.PageHandlerFactory");
}

void BraveWalletPageUI::BindInterface(
    mojo::PendingReceiver<brave_wallet::mojom::PageHandlerFactory> receiver) {
  page_factory_receiver_.reset();
  page_factory_receiver_.Bind(std::move(receiver));
}

void BraveWalletPageUI::CreatePageHandler(
    mojo::PendingRemote<brave_wallet::mojom::Page> page,
    mojo::PendingReceiver<brave_wallet::mojom::PageHandler> page_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::WalletHandler> wallet_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::JsonRpcService>
        json_rpc_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::BitcoinWalletService>
        bitcoin_rpc_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::ZCashWalletService>
        zcash_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::SwapService>
        swap_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::AssetRatioService>
        asset_ratio_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::KeyringService>
        keyring_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::BlockchainRegistry>
        blockchain_registry_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::TxService> tx_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::EthTxManagerProxy>
        eth_tx_manager_proxy_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::SolanaTxManagerProxy>
        solana_tx_manager_proxy_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::FilTxManagerProxy>
        filecoin_tx_manager_proxy_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::BraveWalletService>
        brave_wallet_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::BraveWalletP3A>
        brave_wallet_p3a_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::WalletPinService>
        brave_wallet_pin_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::WalletAutoPinService>
        brave_wallet_auto_pin_service_receiver,
    mojo::PendingReceiver<brave_wallet::mojom::IpfsService>
        ipfs_service_receiver) {
  DCHECK(page);

  auto* browser_state = ChromeBrowserState::FromWebUIIOS(web_ui());
  DCHECK(browser_state);

  page_handler_ = std::make_unique<WalletPageHandler>(std::move(page),
                                                      std::move(page_receiver));

  wallet_handler_ = std::make_unique<brave_wallet::WalletHandler>(
      std::move(wallet_receiver), browser_state);

  brave_wallet::JsonRpcServiceFactory::GetServiceForState(browser_state)
      ->Bind(std::move(json_rpc_service_receiver));

  brave_wallet::BitcoinWalletServiceFactory::GetServiceForState(browser_state)
      ->Bind(std::move(bitcoin_rpc_service_receiver));

  //   brave_wallet::ZCashWalletServiceFactory::GetServiceForState(browser_state)
  //       ->Bind(std::move(zcash_service_receiver));

  brave_wallet::SwapServiceFactory::GetServiceForState(browser_state)
      ->Bind(std::move(swap_service_receiver));

  brave_wallet::AssetRatioServiceFactory::GetServiceForState(browser_state)
      ->Bind(std::move(asset_ratio_service_receiver));
  brave_wallet::KeyringServiceFactory::GetServiceForState(browser_state)
      ->Bind(std::move(keyring_service_receiver));
  brave_wallet::TxServiceFactory::GetServiceForState(browser_state)
      ->Bind(std::move(tx_service_receiver));
  brave_wallet::TxServiceFactory::GetServiceForState(browser_state)
      ->BindEthTxManagerProxy(std::move(eth_tx_manager_proxy_receiver));
  brave_wallet::TxServiceFactory::GetServiceForState(browser_state)
      ->BindSolanaTxManagerProxy(std::move(solana_tx_manager_proxy_receiver));
  brave_wallet::TxServiceFactory::GetServiceForState(browser_state)
      ->BindFilTxManagerProxy(std::move(filecoin_tx_manager_proxy_receiver));
  brave_wallet::BraveWalletIpfsServiceFactory::GetServiceForState(browser_state)
      ->Bind(std::move(ipfs_service_receiver));
  brave_wallet::BraveWalletService* wallet_service =
      brave_wallet::BraveWalletServiceFactory::GetServiceForState(
          browser_state);
  wallet_service->Bind(std::move(brave_wallet_service_receiver));
  wallet_service->GetBraveWalletP3A()->Bind(
      std::move(brave_wallet_p3a_receiver));

  auto* blockchain_registry = brave_wallet::BlockchainRegistry::GetInstance();
  if (blockchain_registry) {
    blockchain_registry->Bind(std::move(blockchain_registry_receiver));
  }
  // brave_wallet::WalletInteractionDetected(web_ui()->GetWebContents());
}
