//
//  ReduxMiddleware.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import Foundation

protocol ReduxMiddleware {
    associatedtype State
    /// Applies the action through this middleware
    func apply(state: @escaping () -> State, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void
}

struct AnyReduxMiddleware<MiddlewareState>: ReduxMiddleware {
    
    typealias State = MiddlewareState
    private let _apply: (_ state: @escaping () -> State, _ dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void
    private let underlyingType: String

    init<M: ReduxMiddleware>(_ middleware: M) where M.State == State {
        self._apply = middleware.apply
        self.underlyingType = "\(type(of: middleware))"
    }
    
    func apply(state: @escaping () -> MiddlewareState, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void {
        return _apply(state, dispatch)
    }
}
