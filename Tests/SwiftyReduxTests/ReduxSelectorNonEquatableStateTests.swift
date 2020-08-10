//
//  ReduxSelectorNonEquatableStateTests.swift
//
//
//  Created by Ricky Powell on 8/9/20.
//

import XCTest
@testable import SwiftyRedux

class ReduxSelectorNonEquatableStateTests: XCTestCase {
    
    struct NumberState {
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
    
    var store: ReduxStore<ReduxSelectorNonEquatableStateTests.NumberState, ReduxSelectorNonEquatableStateTests.NumberReducer>!
    var cancellable: ReduxCancellable!
    
    override func setUp() {
        super.setUp()
        store = ReduxStore(
            initialState: NumberState(value: 9),
            reducer: NumberReducer()
        )
        cancellable = nil
    }
    
    func testNonEquatableState() {
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
            XCTAssertEqual("10", transformedValue)
        }
        store.dispatch(action: IncrementAction())
        wait(for: [called], timeout: 0.5)
    }
}
