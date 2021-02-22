
# Redux

This is a homegrown solution for Redux in swift for the project. Below is examples on how to use it.

## Store

The `ReduxStore` holds all the state. When the store is asked to dispatch an action, then order of events are:
1. preprocess the action through the middleware 
2. process the action through the reducers. Reducer output a new state for the store hold.
3. postprocess the action through the middleware 
4. publish the new state to all the subscribers
Subscribers can be cancelled from receiving any more updates from the store.

> 

At the same time, it appends a historic record between reducer mutations (microHistory) and a then finally a
record is created after all reducers have finished. If the state is `Equatable`, then after each reducer has executed, it's output is compared with the
previous state. If it's different, then the new state is published to the subscribers. Otherwise, the next reducer is executed. Subscibers will not receive
an update until a new state is output.

## State

That that is equatable is preferred because it can be conditionally tested if the state has changed or not and published to the subscribers

## Dispatch and Action

Actions assist in the dispatch of potentially new state and implement `ReduxAction`. Calling `ReduxStore.dispatch(_:)` requires
that you pass in a `ReduxAction`. For every action, the `ReduxStore` iterates through all the reducers and publishes
the changes to the subscribers.

## Selectors

`ReduxSelector` objects represents a way to transform state to another representation.
Use selectors as a way to separate your state from the subscribers. Selectors can be reused
on different UI or for different use cases. This makes it easier to unit test your data transforms.
```
// Declare a selector
struct ToStringSelector: ReduxSelector {
    func select(_ state: Int) -> String {
       return state.description
    }
}
// use the selector
store.subscribe(
    subtree: \.numberState,
    selector: ToStringSelector()
) { newState in
   // newState is a `String`
}
```

Selectors are not required to subsciber to updates in state.

## Middleware

The order of operations after calling `ReduxStore.dispatch(_:)` is as follows:
1. pre-process the given action to each middleware in order at the time the store was initialized
2. call the store's reducer
3. publish the state changes to the subscribers
4. post-process the given action to each middleware in reverse order

```
// Where `S` is the `State`
struct Logging<S>: ReduxMiddleware {
    func apply(state: @escaping () -> S, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void {
        return { next in
            return { action in
                print("before state change \(state())")
                next(action)
                print("after state change \(state())")
            }
        }
    }
}

let intStore = ReduxStore(
    initialState: opInt, 
    reducer: CounterReducer, 
    middlewares: [AnyReduxMiddleware(Logging<CounterState>())]
)
```

> Note: The types of the Middleware need to be erased with `AnyReduxMiddleware`.

## Examples
### Simple integer store with 2 different actions
```
/// Actions

struct Increment: ReduxAction {}
struct Decrement: ReduxAction {}

/// Reducers

struct CounterReducer: ReduxReducer {
    func reduce(action: ReduxAction, state: Int) -> Int {
        switch action {
        case is Increment:
            return value + 1
        case is Decrement:
            return value - 1
        default:
            return state
        }
    }
}

// create a ReduxStore<Int>
let opInt: Int = 2
let intStore = ReduxStore(initialState: opInt, reducer: CounterReducer)
// create a subscription
let subscriber = intStore.subscribe { (state: Int) in
    let x = state
    print(x)
}
let subscriber2 = intStore.subscribe { (newState: Int) -> Void in
    // receive updates with new state
    print("new state: \(newState)")
}
// dispatch some actions
intStore.dispatch(action: Increment())
intStore.dispatch(action: Increment())
intStore.dispatch(action: Decrement())
intStore.dispatch(action: Increment())
intStore.dispatch(action: Increment())
intStore.cancel(subscriber)
intStore.cancel(subscriber2)
```
### Combining Reducers into a single reducer (Aggregate Reducer)
```
// Custom type

struct TodayIsBirthday: ReduxAction {}
struct EatGrapes: ReduxAction {}
struct PurchaseBear: ReduxAction {}
struct PurchaseGoldfish: ReduxAction {}

struct Pet: Equatable {
    let name: String
    let numberOfLegs: Int
}

struct Human: Equatable, CustomDebugStringConvertible {
    var age: Int
    var hunger: String
    var pets: [Pet] = []
    init(age: Int, hunger: String) {
        self.age = age
        self.hunger = hunger
    }
    var debugDescription: String {
        return "<Human age=\(age), hunger=\(hunger), pets=\(pets) />"
    }
}

struct HumanLoggerReducer: ReduxReducer {
    func reduce(action: ReduxAction, state: Human) -> Human {
        print("🤖 logging human <\(state) />")
        return state
    }
}

struct BirthdayReducer: ReduceReducer {
    func reduce(action: ReduxAction, state: Human) -> Human {
        var mutableState = state
        switch action {
        case is TodayIsBirthday:
            mutableState.age += 1
            return mutableState
        default:
            return state
        }
    }
}

struct HaveSnackReducer: ReduceReducer {
    func reduce(action: ReduxAction, state: Human) -> Human {
        var mutableState = state
        switch action {
        case is EatGrapes:
            mutableState.hunger = "satisfied"
            return mutableState
        default:
            return state
        }
    }
}

struct PetStoreReducer: ReduceReducer {
    func reduce (action: ReduxAction, state: Human) -> Human {
        var mutableState = state
        switch action {
        case is PurchaseBear:
            mutableState.pets.append(Pet(name: "🐻 Bear", numberOfLegs: 4))
            return mutableState
        case is TodayIsBirthday:
            mutableState.pets.append(Pet(name: "🎂 Goldfish", numberOfLegs: 0))
            return mutableState
        case is PurchaseGoldfish:
            mutableState.pets.append(Pet(name: "🐠 Goldfish", numberOfLegs: 0))
            return mutableState
        default:
            return state
        }
    }
}

struct HumanReducer: ReduxReducer {
    func reduce(action: ReduxAction, state: Human) -> Human {
        var humanState = state
        humanState = HumanLoggerReducer()
            .reduce(action: action, state: humanState)
        humanState = BirthdayReducer()
            .reduce(action: action, state: humanState)
        humanState = HaveSnackReducer()
            .reduce(action: action, state: humanState)
        humanState = PetStoreReducer()
            .reduce(action: action, state: humanState)
        return humanState
    }
}

// create store
let humanStore = ReduxStore(
    initialState: Human(age: 0, hunger: "very"),
    reducer: HumanReducer()
)
// subscribe to changes
let sub1 = humanStore.subscribe { state in
    let v = state
    print(v.age)
    v.age
    v.pets.map { $0.name }
}
let sub2 = humanStore.subscribe { state in
    print("new state \(state)")
}
// dispacth actions
humanStore.dispatch(TodayIsBirthday())
humanStore.dispatch(PurchaseBear())
humanStore.dispatch(PurchaseGoldfish())
humanStore.dispatch(TodayIsBirthday())
humanStore.dispatch(EatGrapes())
// cancel publications to the subscribers
humanStore.cancel(sub1)
humanStore.cancel(sub2)
```
