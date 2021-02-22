//
//  ReduxReducer.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import Foundation

/// Define a `ReduxReducer` that will be used in the `ReduxStore` to process the new `ReduxAction` objects
/// that are dispatched.
public protocol ReduxReducer {
    /// Type of state the `ReduxReducer` can reduce.
    associatedtype State
    /// Given the `action` and `state`, produce a new `State`.
    ///
    /// - Parameters:
    ///     - action: The action to process that can possibly mutable the output `State`.
    ///     - state: the state to be processed
    /// - Returns:
    ///     the new `State` to be stored in the `ReduxStore`
    func reduce(action: ReduxAction, state: State) -> State
}
