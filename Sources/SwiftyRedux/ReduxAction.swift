
/// Responsible for carrying any information or data related to the action that will inform
/// the `ReduxReducer` objects about why this action occurred.
///
/// Actions are designed to hold zero to many properties with information about the action that has taken place.
/// Actions are discarded after they have finished being processed by the store. The only requirement
/// of `ReduxAction` objects is that they have a concrete type. For example, you could have an action
/// called `struct ClearDataAction: ReduxAction` that has no properties. It's up to the reducers
/// of the store decide how to reduce that action to a new state.
/// ```
/// // example of action that holds what the next number value is
/// struct UpdateNumberAction: ReduxAction {
///     let nextNumber: Int
/// }
/// // example usage
/// store.dispatch(UpdateNumberAction(nextNumber: 99))
/// // the UpdateNumberAction will be processed by the reducers of the store
/// // and will have a copy of the `nextNumber`.
/// ```
public protocol ReduxAction {}
