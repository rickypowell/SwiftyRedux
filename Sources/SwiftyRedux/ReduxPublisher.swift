//
//  ReduxPublisher.swift
//  
//
//  Created by Ricky Powell on 2/20/21.
//

import Foundation

/// Captures new anonymous subscibers to the new state that was processed by the `ReduxStore` reducer.
protocol ReduxPublisher {
    /// The type of state from the `ReduxStore`
    associatedtype State
    /// After every dispatch to the `ReduxStore`, the `subscriber` is invoked giving it the new state.
    func subscribe(_ subscriber: @escaping (State) -> Void) -> ReduxSubscription<State>
    /// After every dispatch, process the new state through the given `selector` before invoking the `subscriber` by passing in the selector's output.
    func subscribe<Selector: ReduxSelector>(
        selector: Selector,
        _ subscriber: @escaping (Selector.TransformedState) -> Void
    ) -> ReduxSubscription<State> where Selector.State == State
    /// After every dispatch, the `subscriber` is invoked giving it the new state on the `path` of the root state.
    func subscribe<Subtree>(
        subtree path: KeyPath<State, Subtree>,
        _ subscriber: @escaping (Subtree) -> Void
    ) -> ReduxSubscription<State>
    /// After every dispatch, the `subscriber` is invoked giving the new state on the `path` of the root state as input to the `selector`.
    /// The output of the `selector` is given as the input into the `subscriber`.
    func subscribe<Selector: ReduxSelector>(
        subtree path: KeyPath<State, Selector.State>,
        selector: Selector,
        _ subscriber: @escaping (Selector.TransformedState) -> Void
    ) -> ReduxSubscription<State>
    /// After every dispatch, the `subscriber` is invoked giving the new state on the `path` of the root state as input to the `selector`
    /// but only if the new state is not equal to the previous state (this is done through `Equatable` states)..
    /// The output of the `selector` is given as the input into the `subscriber`.
    func subscribe<Selector: ReduxSelector>(
        subtree path: KeyPath<State, Selector.State>,
        selector: Selector,
        _ subscriber: @escaping (Selector.TransformedState) -> Void
    ) -> ReduxSubscription<State> where Selector.State: Equatable
}
