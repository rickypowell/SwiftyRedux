//
//  ReduxSelectorEquatableStateTests.swift
//  
//
//  Created by Ricky Powell on 8/9/20.
//

import XCTest
@testable import SwiftyRedux

class ReduxSelectorEquatableStateTests: XCTestCase {
    
    struct NumberState: Equatable {
        var value: Int
    }
    
    struct NumberStateNonEquatable {
        var value: Int
    }
    
    struct IncrementAction: ReduxAction {}
    
    struct NumberReducer: ReduxReducer {
        func reduce(action: ReduxAction, state: NumberState) -> NumberState {
            var mutableState = state
            switch action {
            case is IncrementAction:
                mutableState.value += 1
            default:
                break
            }
            return mutableState
        }
    }
    
    var store: ReduxStore<ReduxSelectorEquatableStateTests.NumberState, ReduxSelectorEquatableStateTests.NumberReducer>!
    var cancellable: ReduxCancellable!
    
    override func setUp() {
        super.setUp()
        store = ReduxStore(
            initialState: NumberState(value: 1),
            reducer: NumberReducer()
        )
        cancellable = nil
    }
    
    func testEquatableState() {
        // test selector
        struct ToStringSelector: ReduxSelector {
            func select(_ state: Int) -> String {
                return state.description
            }
        }
        // setup input
        let called = self.expectation(description: "called")
        cancellable = store.subscribe(
            subtree: \.value,
            selector: ToStringSelector()
        ) { (transformedValue: String) -> Void in
            called.fulfill()
            XCTAssertEqual("2", transformedValue)
        }
        store.dispatch(action: IncrementAction())
        wait(for: [called], timeout: 0.5)
    }
}
