// Copyright (c) 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import * as React from 'react'
import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { Route, Switch, BrowserRouter } from 'react-router-dom'

import { initLocale } from 'brave-ui'

// style
import walletDarkTheme from '../../../../theme/wallet-dark'
import walletLightTheme from '../../../../theme/wallet-light'
import 'emptykit.css'

// Utils
import { loadTimeData } from '../../../../../common/loadTimeData'
import * as Lib from '../../../../common/async/lib'

// actions
import * as WalletActions from '../../../../common/actions/wallet_actions'

// Components
import { store } from '../../../store'
import {
  // eslint-disable-next-line import/no-named-default
  default as BraveCoreThemeProvider
} from '../../../../../common/BraveCoreThemeProvider'
import { SendScreen } from '../send_screen/send_screen'
import { Swap } from '../../swap/swap'
import { LibContext } from '../../../../common/context/lib.context'

// types
import { WalletRoutes } from '../../../../constants/types'

import { setIconBasePath } from '@brave/leo/react/icon'
setIconBasePath('chrome://resources/brave-icons')

export function IOSSendApp() {
  return (
    <Provider store={store}>
      <BrowserRouter>
        <BraveCoreThemeProvider
          dark={walletDarkTheme}
          light={walletLightTheme}
        >
          <LibContext.Provider value={Lib}>
            <Switch>
              <Route path={WalletRoutes.Send}>
                <SendScreen isIOS={true} />
              </Route>
              <Route path={WalletRoutes.Swap}>
                <Swap isIOS={true} />
              </Route>
            </Switch>
          </LibContext.Provider>
        </BraveCoreThemeProvider>
      </BrowserRouter>
    </Provider>
  )
}

function initialize() {
  initLocale(loadTimeData.data_)
  store.dispatch(WalletActions.initialize({}))
  render(IOSSendApp(), document.getElementById('root'))
}

document.addEventListener('DOMContentLoaded', initialize)
