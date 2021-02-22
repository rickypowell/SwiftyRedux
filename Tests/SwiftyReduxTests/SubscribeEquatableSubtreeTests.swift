//
//  SubscribeEquatableSubtreeTests.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import XCTest
@testable import SwiftyRedux

class SubscribeEquatableSubtreeTests: XCTestCase {

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
    
    var equatableSubscriber: ReduxCancellable!
    
    /// When a subscribing to a subtree of state, if the subtree is not different
    /// than the previous time its value was published, then same subtree will not be published again.
    func testExpectationCount() {
        let appReducerExpect = self.expectation(description: "appReducer")
        appReducerExpect.expectedFulfillmentCount = 2
        let store = ReduxStore(
            initialState: EquatableAppState(),
            reducer: EquatableAppReducer(expectation: appReducerExpect)
        )
        let subscriberExpect = self.expectation(description: "subscriber")
        subscriberExpect.expectedFulfillmentCount = 1
        equatableSubscriber = store.subscribe(subtree: \.count, { newState in
            subscriberExpect.fulfill()
            XCTAssertEqual(5, newState)
        })
        store.dispatch(IncrementBy(amount: 5))
        store.dispatch(IncrementBy(amount: 0))
        wait(for: [appReducerExpect, subscriberExpect], timeout: 0.1)
        store.cancel(equatableSubscriber)
    }

}

