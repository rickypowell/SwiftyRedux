//
//  ReduxMiddleware.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import Foundation

public protocol ReduxMiddleware {
    associatedtype State
    /// Applies the action through this middleware
    func apply(state: @escaping () -> State, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void
}

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
