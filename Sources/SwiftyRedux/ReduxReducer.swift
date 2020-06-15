//
//  ReduxReducer.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import Foundation

public protocol ReduxReducer {
    associatedtype State
    func reduce(action: ReduxAction, state: State) -> State
}

public struct AnyReduxReducer<R: ReduxReducer>: ReduxReducer {
    public typealias State = R.State
    private let reducer: R
    public init(_ reducer: R) {
        self.reducer = reducer
    }
    
    public func reduce(action: ReduxAction, state: State) -> State {
        reducer.reduce(action: action, state: state)
    }
}
