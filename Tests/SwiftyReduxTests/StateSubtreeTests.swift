//
//  StateSubtreeTests.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import XCTest
@testable import SwiftyRedux

class StateSubtreeTests: XCTestCase {

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
    
    var subscriber: ReduxSubscription<StateSubtreeTests.AppState>!
    
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
        store.dispatch(action: IncrementBy(amount: 5))
        store.dispatch(action: IncrementBy(amount: 0))
        wait(for: [appReducerExpect, subscriberExpect], timeout: 2)
    }
    
}

