//
//  ReduxSubscription.swift
//  
//
//  Created by Ricky Powell on 6/20/20.
//

import Foundation

public struct ReduxSubscription<State>: Hashable, ReduxCancellable {
    /// Universally uniuque identify for the subscription
    let id: UUID
    /// The callback to publish to the subscriber
    let publish: (State) -> Void
    /// - Parameter id: Universally uniuque identify for the subscription
    /// - Parameter owner: The owner of the this subscription
    /// - Parameter publish: The callback to publish to the subscriber
    init(
        id: UUID,
        publish: @escaping (State) -> Void
    ) {
        self.id = id
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
}
