//
//  ReduxDispatcher.swift
//  
//
//  Created by Ricky Powell on 2/20/21.
//

import Foundation

/// Responsible to dispatching the `ReduxAction` objects to the `ReduxStore`.
protocol ReduxDispatcher {
    /// Given the `ReduxAction`, process the action through the `ReduxStore` middleware, reducers,
    /// and then publishing the new state to the `ReduxSubscription` objects held by the `ReduxStore`.
    func dispatch(_ action: ReduxAction)
}
