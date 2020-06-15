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
open class ReduxStore<State, Reducer: ReduxReducer> where Reducer.State == State {
    
    fileprivate struct WeakBoxSubscription: Hashable {
        weak var content: Subscription?
        func publish(_ state: State) {
            // forward the publish
            content?.publish(state)
        }
    }
    
    open class Subscription: Hashable {
        /// Universally uniuque identify for the subscription
        let id: UUID
        /// The owner of the this subscription
        let owner: ReduxStore<State, Reducer>
        /// The callback to publish to the subscriber
        let publish: (State) -> Void
        /// - Parameter id: Universally uniuque identify for the subscription
        /// - Parameter owner: The owner of the this subscription
        /// - Parameter publish: The callback to publish to the subscriber
        init(id: UUID, owner: ReduxStore<State, Reducer>, publish: @escaping (State) -> Void) {
            self.id = id
            self.owner = owner
            self.publish = publish
        }
        
        /// Only uses `self.id` to compute equality
        public static func == (
            lhs: ReduxStore<State, Reducer>.Subscription,
            rhs: ReduxStore<State, Reducer>.Subscription
        ) -> Bool {
            return lhs.id == rhs.id
        }
        
        /// Only uses `self.id` to compute the hash.
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
        }
        
        deinit {
            self.owner.cancel(self)
        }
    }
    
    private(set) var state: State
    private(set) var reducer: Reducer
    private var subscribers: Set<WeakBoxSubscription> = []
    
    private(set) var middlewares: [AnyReduxMiddleware<State>] = []
    
    /// Creates a store with a initalized state
    init(initialState: State, reducer: Reducer) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = []
    }
    
    /// Creates a store with a initalized state and middleware
    init(initialState: State, reducer: Reducer, middlewares: [AnyReduxMiddleware<State>]) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
    }
    
    /// Pushes the action into the store
    ///
    /// It does this by iterating through all the reducers. At the same time, it appends a historic record between reducer mutations (microHistory) and a then finally a
    /// record is created after all reducers have finished. If the state is `Equatable`, then after each reducer has executed, it's output is compared with the
    /// previous state. If it's different, then the new state is published to the subscribers. Otherwise, the next reducer is executed. Subscibers will not receive
    /// an update until a new state is output.
    open func dispatch(action: ReduxAction) {
        let preMiddlewares = middlewares
            .map {
                return $0.apply(
                    state: { self.state },
                    dispatch: { [weak self] newAction in self?.dispatch(action: newAction) }
                )
        }
        
        if middlewares.count > 0 {
            let initial = { (action: ReduxAction) -> Void in
                let newState = self.reducer.reduce(action: action, state: self.state)
                for subscriber in self.subscribers {
                    subscriber.publish(newState)
                }
                self.state = newState
            }
            let f = preMiddlewares
                .reversed()
                .reduce(initial, { (prev, next) -> (ReduxAction) -> Void in
                    return next(prev)
                })
            f(action)
        } else {
            self.state = self.reducer.reduce(action: action, state: state)
            for subscriber in subscribers {
                subscriber.publish(state)
            }
        }
    }
    
    open func subscribe(_ subscriber: @escaping (State) -> Void) -> ReduxStore.Subscription {
        let subscription = Subscription(
            id: UUID(),
            owner: self,
            publish: subscriber
        )
        let container = WeakBoxSubscription(
            content: subscription
        )
        subscribers.insert(container)
        return subscription
    }
    
    open func subscribe<Subtree>(subtree path: KeyPath<State, Subtree>, _ subscriber: @escaping (Subtree) -> Void) -> ReduxStore.Subscription {
        let subscription = Subscription(
            id: UUID(),
            owner: self) { [subscriber] state in
                subscriber(state[keyPath: path])
        }
        let container = WeakBoxSubscription(
            content: subscription
        )
        subscribers.insert(container)
        return subscription
    }
    
    @discardableResult
    open func cancel(_ subscription: ReduxStore.Subscription) -> ReduxStore.Subscription? {
        return subscribers.remove(
            WeakBoxSubscription(content: subscription)
        )?.content
    }
}

public extension ReduxStore where State: Equatable {
    public func dispatch(action: ReduxAction) {
        let preMiddlewares = middlewares
            .map {
                return $0.apply(
                    state: { self.state },
                    dispatch: { [weak self] newAction in self?.dispatch(action: newAction) }
                )
        }
        
        let previousState = self.state
        if middlewares.count > 0 {
            let initial = { (action: ReduxAction) -> Void in
                let newState = self.reducer.reduce(action: action, state: previousState)
                for subscriber in self.subscribers
                    where previousState != newState {
                    subscriber.publish(newState)
                }
                self.state = newState
            }
            let f = preMiddlewares
                .reversed()
                .reduce(initial, { (prev, next) -> (ReduxAction) -> Void in
                    return next(prev)
                })
            f(action)
        } else {
            let newState = self.reducer.reduce(action: action, state: state)
            for subscriber in subscribers
                where previousState != newState {
                subscriber.publish(newState)
            }
            self.state = newState
        }
    }

    public func subscribe<Subtree: Equatable>(subtree path: KeyPath<State, Subtree>, _ subscriber: @escaping (Subtree) -> Void) -> ReduxStore.Subscription {
        var previous = state[keyPath: path]
        var next = previous
        let subscription = Subscription(
            id: UUID(),
            owner: self) { [subscriber] state in
                next = state[keyPath: path]
                if previous != next {
                    subscriber(state[keyPath: path])
                    previous = next
                }

        }
        let container = WeakBoxSubscription(
            content: subscription
        )
        subscribers.insert(container)
        return subscription
    }
}

