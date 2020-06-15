//
//  ReduxReducer.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import Foundation

protocol ReduxReducer {
    associatedtype State
    func reduce(action: ReduxAction, state: State) -> State
}

struct AnyReduxReducer<R: ReduxReducer>: ReduxReducer {
    typealias State = R.State
    private let reducer: R
    init(_ reducer: R) {
        self.reducer = reducer
    }
    
    func reduce(action: ReduxAction, state: State) -> State {
        reducer.reduce(action: action, state: state)
    }
}
