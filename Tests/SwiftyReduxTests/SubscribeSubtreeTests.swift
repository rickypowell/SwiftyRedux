//
//  SubscribeSubtreeTests.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import XCTest
@testable import SwiftyRedux

class SubscribeSubtreeTests: XCTestCase {

    struct AppState {
        var count: Int = 0
    }
    
    struct AppReducer: ReduxReducer {
        let expectation: XCTestExpectation
        func reduce(action: ReduxAction, state: AppState) -> AppState {
            switch action {
            case let action as IncrementBy:
                expectation.fulfill()
                return AppState(count: state.count + action.amount)
            default:
                return state
            }
        }
    }
    
    struct IncrementBy: ReduxAction {
        let amount: Int
    }
    
    var subscriber: ReduxSubscription<SubscribeSubtreeTests.AppState>!
    
    /// When a subscribing to a subtree of state, then same subtree will be published again even if the substree has not changed.
    func testExpectationCount() {
        let appReducerExpect = self.expectation(description: "appReducer")
        appReducerExpect.expectedFulfillmentCount = 2
        let store = ReduxStore(
            initialState: AppState(),
            reducer: AppReducer(expectation: appReducerExpect)
        )
        let subscriberExpect = self.expectation(description: "subscriber")
        subscriberExpect.expectedFulfillmentCount = 2
        subscriber = store.subscribe(subtree: \.count, { newState in
            subscriberExpect.fulfill()
            XCTAssertEqual(5, newState)
        })
        store.dispatch(IncrementBy(amount: 5))
        store.dispatch(IncrementBy(amount: 0))
        wait(for: [appReducerExpect, subscriberExpect], timeout: 2)
    }
    
}

