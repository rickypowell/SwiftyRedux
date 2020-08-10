//
//  ReduxSelector.swift
//  
//
//  Created by Ricky Powell on 8/9/20.
//

import Foundation

/// Represents a way to transform state to another representation
///
/// Use selectors as a way to separate your state from the subscribers. Selectors can be reused
/// for different UI or for different use cases. This makes it easier to unit test your data transforms.
///
/// ```
/// // Declare a selector
/// struct ToStringSelector: ReduxSelector {
///     func select(_ state: Int) -> String {
///        return state.description
///     }
/// }
/// // use the selector
/// store.subscribe(
///     subtree: \.numberState,
///     selector: ToStringSelector()
/// ) { newState in
///    // newState is a `String`
/// }
/// ```
public protocol ReduxSelector {
    associatedtype State
    associatedtype TransformedState
    /// Transforms the given `state` to a new type of `TransformedState`.
    /// - Parameter state: the initial state
    /// - Returns: a transformed state as a new type and representation
    func select(_ state: State) -> TransformedState
}
