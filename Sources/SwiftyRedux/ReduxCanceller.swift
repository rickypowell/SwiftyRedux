//
//  ReduxCanceller.swift
//  
//
//  Created by Ricky Powell on 2/20/21.
//

import Foundation

/// Responsible for cancelling any further updates that a subscriber will receive.
protocol ReduxCanceller {
    /// Cancels any further updates that the subscriber will receive
    func cancel(_ cancellable: ReduxCancellable)
}

extension ReduxCanceller {
    /// Cancels any further updates that the subscriber will receive if the `cancellable` is non-nil.
    func cancel(_ cancellable: ReduxCancellable?) {
        guard let nonNilCancellable = cancellable else { return }
        self.cancel(nonNilCancellable)
    }
}
