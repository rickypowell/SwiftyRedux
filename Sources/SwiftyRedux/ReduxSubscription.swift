//
//  ReduxSubscription.swift
//  
//
//  Created by Ricky Powell on 6/20/20.
//

import Foundation

open class ReduxSubscription<State, Reducer: ReduxReducer>: Hashable, ReduxCancellable where Reducer.State == State {
    /// Universally uniuque identify for the subscription
    let id: UUID
    /// The owner of the this subscription
    let owner: ReduxStore<State, Reducer>
    /// The callback to publish to the subscriber
    let publish: (State) -> Void
    /// - Parameter id: Universally uniuque identify for the subscription
    /// - Parameter owner: The owner of the this subscription
    /// - Parameter publish: The callback to publish to the subscriber
    init(
        id: UUID,
        owner: ReduxStore<State, Reducer>,
        publish: @escaping (State) -> Void
    ) {
        self.id = id
        self.owner = owner
        self.publish = publish
    }
    
    /// Only uses `self.id` to compute equality
    public static func == (
        lhs: ReduxSubscription,
        rhs: ReduxSubscription
    ) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Only uses `self.id` to compute the hash.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    /// Cancels the subscription
    public func cancel() {
        self.owner.cancel(self)
    }
    
    deinit {
        cancel()
    }
}
