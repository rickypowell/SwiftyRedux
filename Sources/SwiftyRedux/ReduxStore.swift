//
//  ReduxStore.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import Foundation

/// The main driver for the unidirectional data flow model
/// - `State` is the object that holds the values needed during the application lifecycle
/// - `Reducer` is the object that mutates the `State` to a new `State`
open class ReduxStore<State, Reducer: ReduxReducer>:
    ReduxCanceller where Reducer.State == State {
    
    private(set) var state: State
    private(set) var reducer: Reducer
    private var subscribers: Set<ReduxSubscription<State>> = []
    
    private(set) var middlewares: [AnyReduxMiddleware<State>] = []
    
    /// Creates a store with a initalized state
    public init(initialState: State, reducer: Reducer) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = []
    }
    
    /// Creates a store with a initalized state and middleware
    /// - Parameters:
    ///     - initialState: setup the initial state and pass it to the initializer of the store
    ///     - reducer: the aggregate reducer of the store that will recieve the dispatched action
    ///     - middlewares: interceptors of all the actions that are dispatched and responsible for allowing or denying the action to be processed by the `reducer`.
    public init(initialState: State, reducer: Reducer, middlewares: [AnyReduxMiddleware<State>]) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
    }
    
    /// Pushes the action into the store
    ///
    /// It does this by iterating through all the reducers. If the state is `Equatable`, then after each reducer has executed, it's output is compared with the
    /// previous state. If it's different, then the new state is published to the subscribers. Otherwise, the next reducer is executed. Subscibers will not receive
    /// an update until a new state is output.
    open func dispatch(_ action: ReduxAction) {
        let f: (ReduxAction) -> Void = middlewares
            .map {
                return $0.apply(
                    state: { self.state },
                    dispatch: { [weak self] newAction in self?.dispatch(newAction) }
                )
        }
        .lazy
        .reversed()
        .reduce({ (action: ReduxAction) -> Void in
            let newState = self.reducer.reduce(action: action, state: self.state)
            for subscriber in self.subscribers {
                subscriber.publish(newState)
            }
            self.state = newState
        }) { (prev, next) -> (ReduxAction) -> Void in
            return next(prev)
        }
        f(action)
    }
    
    open func subscribe(_ subscriber: @escaping (State) -> Void) -> ReduxSubscription<State> {
        let subscription = ReduxSubscription<State>(
            id: UUID(),
            publish: subscriber
        )
        subscribers.insert(subscription)
        return subscription
    }
    
    open func subscribe<Selector: ReduxSelector>(
        selector: Selector,
        _ subscriber: @escaping (Selector.TransformedState) -> Void
    ) -> ReduxSubscription<State> where Selector.State == State {
        let subscription = ReduxSubscription<State>(
            id: UUID()
        ) { [subscriber] state in
            subscriber(selector.select(state))
        }
        subscribers.insert(subscription)
        return subscription
    }
    
    open func subscribe<Subtree>(
        subtree path: KeyPath<State, Subtree>,
        _ subscriber: @escaping (Subtree) -> Void
    ) -> ReduxSubscription<State> {
        let subscription = ReduxSubscription<State>(
            id: UUID()
        ) { [subscriber] state in
            subscriber(state[keyPath: path])
        }
        subscribers.insert(subscription)
        return subscription
    }
    
    /// Subscriber to the subtree of changes as new state values occur.
    open func subscribe<Selector: ReduxSelector>(
        subtree path: KeyPath<State, Selector.State>,
        selector: Selector,
        _ subscriber: @escaping (Selector.TransformedState) -> Void
    ) -> ReduxSubscription<State> {
        let subscription = ReduxSubscription<State>(
            id: UUID()
        ) { [subscriber] state in
            subscriber(selector.select(state[keyPath: path]))
        }
        subscribers.insert(subscription)
        return subscription
    }
    
    /// Subscriber to the subtree of changes as new state values occur.
    /// Equatable comparison between the old value and new value for using the selector and publishing the change to the subscriber.
    open func subscribe<Selector: ReduxSelector>(
        subtree path: KeyPath<State, Selector.State>,
        selector: Selector,
        _ subscriber: @escaping (Selector.TransformedState) -> Void
    ) -> ReduxSubscription<State> where Selector.State: Equatable {
        var previous = state[keyPath: path]
        var next = previous
        let subscription = ReduxSubscription<State>(
            id: UUID()
        ) { [subscriber] state in
            next = state[keyPath: path]
            if previous != next {
                subscriber(selector.select(state[keyPath: path]))
                previous = next
            }
        }
        subscribers.insert(subscription)
        return subscription
    }
    
    /// Removes the given `subscription` from receiving any new `State` chances
    /// - Parameter subscription: the object that should stop receiving new `State` changes.
    @discardableResult
    open func cancel(_ subscription: ReduxSubscription<State>) -> ReduxSubscription<State>? {
        return subscribers.remove(
            subscription
        )
    }
    
    /// Removes the underying `ReduxSubscription` in the`cancellable` from receiving any new `State` chances
    /// - Parameter cancellable: the object whos underlying `ReduxSubscription` will be removed from receiving any new
    ///  published `State` values
    open func cancel(_ cancellable: ReduxCancellable) {
        guard let subscription = cancellable as? ReduxSubscription<State> else { return }
        cancel(subscription)
    }
}

public extension ReduxStore where State: Equatable {
    func dispatch(_ action: ReduxAction) {
        let previousState = self.state
        let f: (ReduxAction) -> Void = middlewares
            .map {
                return $0.apply(
                    state: { self.state },
                    dispatch: { [weak self] newAction in self?.dispatch(newAction) }
                )
        }
        .lazy
        .reversed()
        .reduce({ (action: ReduxAction) -> Void in
            let newState = self.reducer.reduce(action: action, state: self.state)
            for subscriber in self.subscribers
                where previousState != newState {
                subscriber.publish(newState)
            }
            self.state = newState
        }) { (prev, next) -> (ReduxAction) -> Void in
            return next(prev)
        }
        f(action)
    }

    func subscribe<Subtree: Equatable>(subtree path: KeyPath<State, Subtree>, _ subscriber: @escaping (Subtree) -> Void) -> ReduxSubscription<State> {
        var previous = state[keyPath: path]
        var next = previous
        let subscription = ReduxSubscription<State>(
            id: UUID()
        ) { [subscriber] state in
            next = state[keyPath: path]
            if previous != next {
                subscriber(state[keyPath: path])
                previous = next
            }
        }
        subscribers.insert(subscription)
        return subscription
    }
}

