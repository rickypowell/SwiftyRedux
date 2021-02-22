//
//  ReduxMiddleware.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import Foundation

/// Responsible for intercepting of all the actions that are dispatched and responsible for allowing or denying the action to be processed by the reducer.
public protocol ReduxMiddleware {
    associatedtype State
    /// Applies the dispatched action through this middleware.
    ///
    /// Typically, the best place to start for implementation of a middleware is as follows:
    /// ```
    /// func apply(state: @escaping () -> S, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void {
    ///     return { next in
    ///         return { action in
    ///             print("before action is passed to the reducer")
    ///             next(action)
    ///             print("after action is passed to the reducer")
    ///         }
    ///     }
    /// }
    /// ```
    /// Neglecting to call `next(action)` results in an action that never reaches the reducer.
    func apply(state: @escaping () -> State, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void
}

/// A type-erasure for `ReduceMiddleware` so that all the middlewares can be stored in a collection.
public struct AnyReduxMiddleware<MiddlewareState>: ReduxMiddleware {
    
    public typealias State = MiddlewareState
    private let _apply: (_ state: @escaping () -> State, _ dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void
    private let underlyingType: String

    public init<M: ReduxMiddleware>(_ middleware: M) where M.State == State {
        self._apply = middleware.apply
        self.underlyingType = "\(type(of: middleware))"
    }
    
    public func apply(state: @escaping () -> MiddlewareState, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void {
        return _apply(state, dispatch)
    }
}
