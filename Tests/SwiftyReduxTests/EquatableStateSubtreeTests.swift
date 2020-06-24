//
//  EquatableStateSubtreeTests.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import XCTest
@testable import SwiftyRedux

class EquatableStateSubtreeTests: XCTestCase {

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
    
//    var equatableSubscriber: ReduxSubscription<EquatableStateSubtreeTests.EquatableAppState, EquatableStateSubtreeTests.EquatableAppReducer>!
    
    var equatableSubscriber: ReduxCancellable!
    
    func testExpectationCount() {
        let appReducerExpect = self.expectation(description: "appReducer")
        appReducerExpect.expectedFulfillmentCount = 2
        let store = ReduxStore(
            initialState: EquatableAppState(),
            reducer: EquatableAppReducer(expectation: appReducerExpect)
        )
        let subscriberExpect = self.expectation(description: "subscriber")
        equatableSubscriber = store.subscribe(subtree: \.count, { newState in
            subscriberExpect.fulfill()
            XCTAssertEqual(5, newState)
        })
        store.dispatch(action: IncrementBy(amount: 5))
        store.dispatch(action: IncrementBy(amount: 0))
        wait(for: [appReducerExpect, subscriberExpect], timeout: 2)
    }

}

