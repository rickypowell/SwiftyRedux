//
//  SubscribeEquatableSubtreeSelectorTests.swift
//  
//
//  Created by Ricky Powell on 2/20/21.
//

import XCTest
@testable import SwiftyRedux

class SubscribeEquatableSubtreeSelectorTests: XCTestCase  {
    struct EquatableAppState: Equatable {
        var count: Int = 0
    }
    
    struct EquatableAppReducer: ReduxReducer {
        let expectation: XCTestExpectation
        func reduce(action: ReduxAction, state: EquatableAppState) -> EquatableAppState {
            switch action {
            case let action as IncrementBy:
                expectation.fulfill()
                return EquatableAppState(count: state.count + action.amount)
            default:
                return state
            }
        }
    }
    
    struct IncrementBy: ReduxAction {
        let amount: Int
    }
    
    struct ToStringSelector: ReduxSelector {
        let expectation: XCTestExpectation
        func select(_ state: Int) -> String {
            expectation.fulfill()
            return state.description
        }
    }
    
    var equatableSubscriber: ReduxCancellable!
    
    /// When a subscribing to a subtree of state while applying a selector, if the input of the selector (the subtree) is not different
    /// than the previous time it ran, then selector will be run again until that subtree has changed.
    func testExpectationCount() {
        let appReducerExpect = self.expectation(description: "appReducer")
        appReducerExpect.expectedFulfillmentCount = 2
        let store = ReduxStore(
            initialState: EquatableAppState(),
            reducer: EquatableAppReducer(expectation: appReducerExpect)
        )
        let subscriberExpect = self.expectation(description: "subscriber")
        subscriberExpect.expectedFulfillmentCount = 1
        let selectorExpect = self.expectation(description: "selector")
        selectorExpect.expectedFulfillmentCount = 1
        let expectedOutput = "5"
        equatableSubscriber = store.subscribe(
            subtree: \.count,
            selector: ToStringSelector(expectation: selectorExpect)
        ) { newState in
            subscriberExpect.fulfill()
            XCTAssertEqual(expectedOutput, newState)
        }
        store.dispatch(IncrementBy(amount: 5))
        store.dispatch(IncrementBy(amount: 0))
        wait(for: [appReducerExpect, subscriberExpect, selectorExpect], timeout: 0.1)
        store.cancel(equatableSubscriber)
    }
}
