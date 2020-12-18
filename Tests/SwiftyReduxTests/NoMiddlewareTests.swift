//
//  NoMiddlewareTests.swift
//  
//
//  Created by Ricky Powell on 6/15/20.
//

import XCTest
@testable import SwiftyRedux

class NoMiddlewareTests: XCTestCase {

    struct AppState {}
    
    struct AppReducer: ReduxReducer {
        let expectation: XCTestExpectation
        func reduce(action: ReduxAction, state: AppState) -> AppState {
            self.expectation.fulfill()
            return state
        }
    }
    
    struct TestAction: ReduxAction {}
    
    var subscriber: ReduxSubscription<NoMiddlewareTests.AppState>!
    
    func testNoMiddlewareOrder() {
        let appReducerExpect = self.expectation(description: "appReducer")
        let store = ReduxStore(
            initialState: AppState(),
            reducer: AppReducer(expectation: appReducerExpect)
        )
        let subscriberExpect = self.expectation(description: "subscriber")
        subscriber = store.subscribe { newState in
            subscriberExpect.fulfill()
        }
        store.dispatch(action: TestAction())
        wait(
            for: [appReducerExpect, subscriberExpect],
            timeout: 2,
            enforceOrder: true
        )
    }

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
    
    var equatableSubscriber: ReduxSubscription<NoMiddlewareTests.EquatableAppState>!
    
    func testNoMiddlewareOrderEquatable() {
        let appReducerExpect = self.expectation(description: "appReducer")
        appReducerExpect.expectedFulfillmentCount = 2
        let store = ReduxStore(
            initialState: EquatableAppState(),
            reducer: EquatableAppReducer(expectation: appReducerExpect)
        )
        let subscriberExpect = self.expectation(description: "subscriber")
        equatableSubscriber = store.subscribe { newState in
            subscriberExpect.fulfill()
            XCTAssertEqual(5, newState.count)
        }
        store.dispatch(action: IncrementBy(amount: 5))
        store.dispatch(action: IncrementBy(amount: 0))
        wait(for: [appReducerExpect, subscriberExpect], timeout: 2)
    }
    
}

